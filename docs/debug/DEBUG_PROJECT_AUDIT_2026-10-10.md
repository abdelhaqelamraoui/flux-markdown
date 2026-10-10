# FluxMarkdown 项目盘点与优化建议

审查日期：2026-10-10。基线：`6f1ecf2`，初始工作区干净。

项目的 Swift 加 WKWebView 架构适合现有功能，值得继续维护。当前最需要投入的是文档执行边界、异步渲染一致性、真实引擎测试和可重复构建。已经复现的问题比整体重写的收益更明确；建议先完成下面的第一批修复，再以性能数据决定拆分和优化范围。

本次覆盖主程序、QuickLook、Shared 资源与偏好设置设施、TypeScript 渲染和交互、测试、构建、依赖、发布脚本、OpenSpec 与性能基线。属于源码审查和定向运行验证，不等同于所有 macOS 版本、真实 Finder 操作、安装升级和全部图表格式的端到端认证。此次只提交审查文档及复现材料，未修改产品实现、依赖锁、部署目标或发布状态。

## 验证结果

| 检查 | 结果与限制 |
| --- | --- |
| Jest 现有测试 | 36 suites，340 tests，全部通过 |
| 定向缺陷探针 | 4 个探针全部确认当前缺陷；详见复现材料，不能作为修复后的期望行为 |
| Vite 生产构建 | 通过；产物目录约 6.1 MiB，目录大小不等于启动加载量 |
| TypeScript 独立检查 | `tsc --noEmit` 失败，8 处 TS1323 |
| Swift 原配置 | 本机 Xcode 27.0 拒绝 macOS 11.0 部署目标，未进入测试 |
| Swift 诊断配置 | 仅命令行覆盖 `MACOSX_DEPLOYMENT_TARGET=12.0`，285 tests 全部通过，跳过性能测试；不是最低系统兼容性证明 |
| 实际 WKWebView 探针 | 使用生产 dist 与仓库 RendererBundleSchemeHandler；HTML onerror 执行成功，import.meta Function 构造抛 SyntaxError |
| 文档内部链接 | 通过 |
| 飞书通知脚本测试 | 7 tests 通过，未发送消息 |
| vendor installer 测试 | 4 tests 通过 |
| OpenSpec | 14 个 change 严格校验通过；无 specs 基线目录 |
| npm audit | 全量 60 个受影响依赖条目；生产依赖 14 个，其中 high 4、moderate 10；这是审计图中的条目数，不是 60 个独立漏洞或 14 个已证实可利用路径 |

## 第一批需要修复的问题

### 1 P1 文档 HTML 可以执行脚本

位置：`web-renderer/src/index.ts:356`、`:945`；`Sources/Shared/LocalSchemeHandler.swift:104`；三个 native WebView 的配置与消息处理。

MarkdownIt 开启 `html: true`，渲染结果未经清洗直接写入 `innerHTML`。输入 `<img src="missing.png" onerror="window.__auditExecuted=true">`，Jest DOM 和实际 WKWebView 都得到 `__auditExecuted === true`。这不是关于 script 标签执行方式的推测。

文档与可信渲染器共用页面上下文，且页面可访问 native 消息入口。LocalSchemeHandler 允许读取文档目录内的资源，并不限于明确引用的图片；相对目录外图片则另有白名单。因此，仅依靠路径包含校验不能构成完整的文档信任边界。此次没有读取用户敏感文件、发起数据外传，或证明任意原生代码执行。

建议明确支持的 HTML 子集，在插入 DOM 前清洗事件属性、危险 URL、嵌套文档等主动内容；保留经过验证的图片、表格、details 和数学标签。补充 CSP、消息来源和类型校验，以及资源类型和大小策略。CSP 应结合实际 Mermaid、WASM 和样式加载验证。对既有 `allowUniversalAccessFromFileURLs` 设置，应先验证 bundle 与本地图片需求再收紧。

验收：无害 onerror 探针不能执行；SVG、iframe、链接协议及错误输出用例覆盖三个宿主；合法 HTML、KaTeX、Mermaid 不回退。markdown-it 官方也要求开启 HTML 时搭配外部清洗器：[安全说明](https://github.com/markdown-it/markdown-it/blob/master/docs/safety.md)。

### 2 P1 旧渲染可覆盖新文档

位置：`web-renderer/src/index.ts:784`、`:899`、`:945`；`Sources/MarkdownPreview/PreviewViewController.swift:1352`。

实际复现：并发发起 `renderMarkdown('# OLD\n\n$x$', {enableKatex:true})` 和 `renderMarkdown('# NEW', {enableKatex:false})`，等待两者结束，最终标题是 OLD。旧请求在动态 import 处挂起，恢复后仍能提交 DOM。

Swift 的 renderVersion 当前主要进入图片 URL，并没有在 JS 提交前比较最新请求。QuickLook 的 `Task.detached` 完成顺序同样可能颠倒；App 的 navigationRenderVersion 仅过滤回调，不能撤销已经发生的 JS DOM 写入。

建议所有 renderMarkdown、renderSource 和文件切换共用递增 generation，Swift 在异步取图后、JS 在每个异步阶段后及最终提交前校验。渲染状态与 parser 配置应属于当前请求。取消仅用于节省工作，正确性必须依赖 generation 校验。

验收：可控延迟的旧请求最后完成时，页面、目录、状态、滚动恢复及搜索就绪状态始终属于新文件；覆盖切换源码模式、主题、快速刷新及关闭窗口。

### 3 P1 Typst 原生路径必然在 Function 构造处失败

位置：`web-renderer/src/typst-renderer.ts:46`；`web-renderer/test/typst-rendering.test.ts`。

`new Function('return import.meta')()` 在实际 WKWebView 返回 `SyntaxError: import.meta is only valid inside modules.`。因此，即使前面的模块成功加载，也会在构造 WASM URL 前失败；App 实际进入转译降级路径。被拒绝的初始化 Promise 还会缓存到后续调用。

建议用构建器可静态分析的 WASM URL 导入，例如合适的 `?url` 导入或字面量 `new URL(..., import.meta.url)`；校验最终产物中 WASM 文件和 scheme MIME。失败后允许受控重试，并将降级原因通过 Swift 日志桥记录。现有 Typst 测试只验证转译和自建 MarkdownIt fence 逻辑，未覆盖实际 App WASM 路径。

验收：真实 WKWebView 从本地 bundle 成功输出 native SVG，断网可用；QuickLook 转译路径仍通过；加载失败的降级和重试有测试。语法依据：[import.meta](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/import.meta)。

### 4 P1 CLI PDF 导出没有等待渲染完成

位置：`Sources/Markdown/CLIExporter.swift:159` 附近的 evaluateJavaScript 与 3 秒延迟。

代码调用异步 `renderMarkdown` 后丢弃 Promise，只在 3 秒后打印。图表、WASM 或图片超过 3 秒时，PDF 可能缺内容；简单文档又被强制延迟。导航失败仅记录日志，缺少统一超时退出。这里已确认代码路径，但未以慢网络实际生成缺失 PDF。

建议与 App 一样使用 callAsyncJavaScript 等待渲染 Promise，再等待字体和图片就绪；增加可诊断超时、明确退出码和输出完成验证。不能无限等待失败的远程图片，应定义超时后报错还是带提示导出。

验收：人为延迟图表超过 3 秒仍得到完整 PDF；损坏资源有确定结果；无图文档无需固定等待；进程在导航失败时及时退出。

### 5 P1 生产依赖存在需要处置的安全公告

证据：[依赖审计快照](audit-2026-10-10/dependency-summary.json)。生产依赖 14 个受影响条目中，high 包括 markdown-it、linkify-it、js-yaml 和 lodash-es。解析器直接消费用户文档，CPU 消耗类公告与本项目使用场景相关。

建议先处理解析器和运行时依赖，再处理构建及测试工具；逐项检查锁文件实际版本、传递依赖和可达路径。不要直接执行 `npm audit fix --force`：当前建议包含 Jest、markdown-it 的跨主版本调整，以及 KaTeX 插件的特殊版本变更。`@iktakahiro/markdown-it-katex` 与顶层 KaTeX 也要同时核查。

验收：记录每个残留公告的范围和处置原因；所有渲染 fixture、真实 WebKit 图表与冷启动测试通过。审计数字随公告库变化，不应作为长期固定阈值。

## 第二批可靠性和工程质量问题

### 6 P2 插件启停依赖历史状态

位置：`web-renderer/src/index.ts:885` 至 `:908`。

先渲染启用 KaTeX 与 Emoji 的文档，再以 `enableKatex:false, enableEmoji:true` 渲染 `:smile:`，输出保留原始 shortcode。原因是 Emoji 启用检查在前，禁用 KaTeX 在后重建 parser，又清掉 Emoji；下一轮才恢复。

建议根据配置键取得完整构造好的 parser，或把插件启停改成一次统一重建。不能在共享 parser 上跨 await 修改状态。验收覆盖 Emoji、KaTeX 组合和全部切换方向，并验证并发请求。

### 7 P2 类型检查未进入构建门禁

位置：`web-renderer/tsconfig.json`、`package.json`、`.github/workflows/ci.yml`。

当前 `module: es6` 与动态 import 冲突，独立 tsc 报 8 个 TS1323；Vite 通过不代表类型检查通过。`noImplicitAny` 也不等于 `strict`。源码存在 `as any` 和 `@ts-ignore`，与 openspec/project.md 声明不符。

建议先把模块目标与实际构建匹配，新增 typecheck 脚本并接入 CI；之后分批启用严格选项、统一 RenderOptions 和 window bridge 类型。不要一次启用全部 lint 规则制造大面积无关修改。[Vite 官方说明](https://vite.dev/guide/features.html)明确区分转译与类型检查。

验收：`npm ci`、独立 typecheck、测试、生产构建在干净 checkout 全部通过。

### 8 P2 最低系统支持与工具链没有形成一致约束

位置：`project.yml`、`web-renderer/vite.config.ts`、CI 中 Xcode 16.4 固定路径。

项目声明 macOS 11，当前本机 Xcode 27 的最低可编译目标为 12。Vite 7 配置没有显式 build.target，安装版本默认包含 Safari 16，未明确对应最低 macOS 的 WebKit。原生 deployment target 本身不能约束 JS 语法和浏览器 API。

建议明确产品支持矩阵和维护工具链：若继续支持 macOS 11，保留可构建它的 Xcode，并为 JS 语法、浏览器 API、WASM 做最低系统验证；若提高最低系统，按产品兼容性变更处理。不要把本次诊断用的 target=12 覆盖直接写回项目。

验收：最低系统上的真实 Finder、App、图表、搜索、导出冒烟通过，并记录 Intel/Apple Silicon 覆盖范围。此次只证明配置不一致，未断言所有 macOS 11 安装都会失败。

### 9 P2 大文件读取和 UTF8 截断边界

位置：`Sources/MarkdownPreview/PreviewViewController.swift:1226`、`:1267`、`:2073`；`Sources/Markdown/MarkdownDocument.swift`。

QuickLook 在主队列读取文件，首次读取与刷新重复实现 500 KiB 截断。若截断点落在中文或 emoji 的多字节字符内部，`String(data:encoding:.utf8)` 整段失败，返回 Encoding Error，而非可用的前缀。App 的文档读取没有相同预览上限。

建议提取带大小限制和 UTF8 边界处理的读取服务；将文件 I/O 移出主线程，结果通过 generation 提交；先定义各宿主大文件策略再统一。慢磁盘或云盘的实际卡顿幅度还需测量。

验收：第 512000 字节截到中文/emoji 内部仍显示合法前缀；首次读取与刷新行为一致；读失败能传递给调用者并有可见反馈。当前 preparePreview 的 handler(nil) 在实际读取前调用，后续失败仅日志记录，也应纳入检查。

### 10 P2 图片大小限制并未覆盖所有加载路径

位置：`Sources/Shared/MarkdownImageDataCollector.swift`、`LocalSchemeHandler.swift:49`。

base64 路径已有数量、单图和总量预算，是已有的有效防护。但超预算图片会回落到 local-md，而 scheme handler 全量 Data(contentsOf:) 读取，没有对应大小上限；不能把 collector 的 8 MiB 当作整个图片链路的预算。

建议统一资源预算，区分单图、文档累计和渲染解码成本；异步资源任务需要正确响应 stop，避免取消后发送回调。图片引用识别当前使用正则，引用式 Markdown 图片等语法也应与 markdown-it 的实际解析结果对齐。

验收：大图片、多个图片、取消预览、引用式图片、文件名括号/空格、父目录引用与软链接边界有真实资源测试。

### 11 P2 发布存在部分成功状态

位置：`scripts/release.sh:116` 起，`scripts/publish-release.sh`。

release.sh 先提交版本、创建并推送 tag，再构建产物。后续失败会留下已推送版本；publish-release.sh 先公开 GitHub release，再更新 Sparkle 与 Homebrew，部分失败被弱化为警告，最后仍打印成功。现有 release-manifest、entitlement 校验和远程 universal 构建已经提供了可靠基础，但尚未构成整个流程的恢复协议。

建议把预检、产物准备、校验、公开发布、分发渠道更新分别记录状态，支持从失败阶段继续。对必须绑定 tag 的远程构建，可保留 tag 预先存在，但应校验冲突并明确失败重试策略。最终输出应报告每个渠道的实际状态。

验收：模拟构建失败、tag 已存在、appcast 推送失败和 Homebrew 更新失败，可安全重试且不会错误标记全部成功。此次只审查脚本，没有运行发布命令。

## 更好的实现方式与性能改进

| 当前实现 | 建议方式 | 收益和验收 |
| --- | --- | --- |
| QuickLook 控制器 2110 行，App WebView 1060 行，renderer 入口 1363 行 | 优先提取 RenderSession、共享配置/bridge、文档读取与资源服务；UI 生命周期仍归宿主管理 | 以异步一致性修复为切入点，减少三个宿主渲染和导出行为分叉；不以文件变小为唯一目标 |
| extractOutline 调用 md.parse，随后 md.render 再解析 | 单次 parse，复用 tokens 生成目录与 HTML | 验证 source range、插件环境、重复标题和 YAML offset，再比较大文档 parse 时间 |
| 每次 render 完成后 setTimeout 预加载 Mermaid，即使禁用或无图表 | 明确预取策略，优先按需或经过空闲预算的预取 | 降低普通文档后续 CPU/内存；比较冷启动和首次图表延迟，不能只比较主 Promise 耗时 |
| 所有图表按阶段串行处理，Vega View 未显式 finalize | 为各 renderer 定义任务与释放协议，必要时限制并发 | 先测量再并行；Mermaid 有共享状态，不能直接全量 Promise.all；Vega 的实际资源保留需运行时确认 |
| 大块 innerHTML 替换，搜索状态与异步任务持有旧 DOM | 提供统一 render lifecycle，明确搜索重建、节点引用释放、事件清理时点 | 覆盖打开搜索后刷新、连续切换文档、内存稳定性；先保证全量渲染正确，再评估增量 DOM |
| Makefile 每次 npm install、重建项目、clean build | 锁文件变更时 npm ci；常规增量构建；clean 单独显式目标 | 干净与增量构建产物一致；记录开发构建耗时，减少不必要的依赖解析 |
| package build 使用 macOS 专用 sed，隐藏 Vite 日志 | 构建配置或跨平台脚本处理资源属性；保留 warning | Linux CI 也能构建 renderer，资源加载路径有真实 WebKit 测试 |
| renderer、Swift、CLI 各自维护字符串桥接 | 类型明确的 RenderRequest/RenderResult，约定 ready/rendered/failed 和 generation | 错误可传播、导出可等待、消息可验证；性能指标可在同一协议记录 |

不建议此时引入 React/Vue、整体迁移原生 Markdown 渲染，或立即把全部解析迁移 Worker。现有专用模块和 DOM 交互已经足够支撑产品；先修复正确性并取得大文档性能数据，再决定 Worker、分块渲染或虚拟化的必要性。

## 测试与项目知识维护

已有好的基础包括 bundle scheme 的路径和软链接边界检查、图片采集预算、独立偏好与布局逻辑测试、renderReady 握手、KaTeX/Mermaid 动态加载、共享源码模块，以及发布产物校验。highlight.js 已经按语言注册，Mermaid 已按主题缓存初始化，资源也已经分包；不要按旧文档重复做这些优化。

当前弱点是替身测试与实际引擎之间缺少连续验证。Typst fence 测试重新实现局部逻辑；Vega、Graphviz 等使用 mock；RenderVersionTests 只验证计数器递增。这些测试有价值，但不能证明异步状态、产物加载和宿主集成正确。建议增加少量高价值真实 WKWebView 测试，覆盖安全输入、并发切换、实际本地 WASM、导出与主题切换，保留大量快速单元测试。

`benchmark/results/js-bench-latest.json` 的时间是 2026-02-21，当前不能据此判断十月版本性能。建议重建基线并记录 commit、系统、硬件、构建模式、样本数、首次正文出现、全部图表完成、CPU/内存峰值。现有 JS benchmark 的部分细项为 null，应先修复测量再提出毫秒级目标。本次未重跑完整三层 benchmark，因此不承诺任何优化百分比。

`openspec/project.md` 仍描述单 HTML、全量 highlight、未注册 LocalSchemeHandler，与源码不符；`web-renderer/AGENTS.md` 仍提 singlefile 和不存在的 npm run dev。14 个 changes 严格校验通过，但多项完成后未归档，`openspec/specs` 不存在。建议先核对已发布功能再归档和形成能力基线，不能只凭任务勾选自动归档未完成验收的变更。

## 建议执行顺序

1. 第一批：HTML 信任边界、渲染 generation、Typst 资源加载、CLI 完成协议和生产依赖处置。每项独立回归、独立提交；安全模式与共享渲染架构变更按 OpenSpec 建立 proposal。
2. 第二批：parser 配置一致性、typecheck CI、最低系统矩阵、文件与图片预算、读取错误处理。先补失败用例，再实现。
3. 第三批：刷新真实性能基线，实施单次 parse、预取策略、增量构建、必要的模块提取和发布恢复流程。

每项验收通过后再推进下一项。预计工作量取决于最低系统设备、HTML 兼容范围及图表 fixture；目前不应给未经验证的固定排期。完整的架构与安全实施方案应在相应 proposal 中列出兼容取舍，本次盘点不等于批准所有架构变更。

## 可重复执行的证据

[renderer 探针](audit-2026-10-10/renderer-probes.test.ts.txt)验证当前缺陷，故意不放入常规测试目录。复制为 `web-renderer/test/audit-probe.test.ts`，在 web-renderer 执行 `npm test -- --runInBand test/audit-probe.test.ts`，执行后删除临时文件。修复之后应将断言改成期望行为，再加入正式回归套件。

[真实 WKWebView 探针](audit-2026-10-10/native-main.swift.txt)只执行无害变量赋值，不读取外部文档或发送网络请求。先构建 renderer，再复制该文件为临时目录中的 main.swift，用 `swiftc Sources/Shared/RendererBundleSchemeHandler.swift <临时目录>/main.swift -o <临时目录>/probe` 编译，传入 `web-renderer/dist` 绝对路径运行。本次结果为：

```text
EVENTS ["didFinish", "rendererReady"]
PROBE success({"executed":true,"metaError":"SyntaxError: import.meta is only valid inside modules."})
```

这一轮没有复现握手顺序反转，因此不把握手竞态列为已确认缺陷；仍适合补充生命周期测试。首次未等 rendererReady 的探针失败后，已改成按握手触发检查。
