# Troubleshooting Guide

> 普通用户建议先看：[`HELP.md`](HELP.md)（由浅入深、尽量不需要理解内部原理）。

## Extension Not Registered

### Issue
运行 `qlmanage -m | grep -i markdown` 或 `pluginkit -m -A -D -p com.apple.quicklook.preview | grep markdownquicklook` 没有找到扩展。

### Root Cause 1：未通过 Xcode 正确运行 Host App
Quick Look 扩展的注册机制要求：
1. 扩展必须通过 **Xcode Run** 运行，而不是简单的 `open` 命令
2. macOS 会缓存扩展列表，需要特殊的刷新流程

### Root Cause 2：扩展没有开启沙箱（Sandbox）
如果在日志中看到类似：

```bash
Ignoring mis-configured plugin ... plug-ins must be sandboxed
```

说明扩展本身没有启用 App Sandbox，`pkd` 会直接拒绝注册该插件，即使它已经被打包进 `.app` 中。

修复方式（已经在当前项目中完成）：

1. 为 Host App 和 Extension 分别添加 Entitlements 文件：
   - `Sources/Markdown/Markdown.entitlements`
   - `Sources/MarkdownPreview/MarkdownPreview.entitlements`

2. 在两个 target 的设置中都启用沙箱，并允许用户选择的文件只读访问：

   ```xml
   <!-- 必须：开启 App Sandbox -->
   <key>com.apple.security.app-sandbox</key>
   <true/>

   <!-- 推荐：允许读取用户在 Finder 中选择的 markdown 文件 -->
   <key>com.apple.security.files.user-selected.read-only</key>
   <true/>

   <!-- 仅限开发环境：允许调试器附加 -->
   <key>com.apple.security.get-task-allow</key>
   <true/>
   ```

3. 在 `project.yml` 中为两个 target 指定 `CODE_SIGN_ENTITLEMENTS`（当前仓库已配置好）：

   ```yaml
   Markdown:
     settings:
       CODE_SIGN_ENTITLEMENTS: Sources/Markdown/Markdown.entitlements

   MarkdownPreview:
     settings:
       CODE_SIGN_ENTITLEMENTS: Sources/MarkdownPreview/MarkdownPreview.entitlements
   ```

4. 重新生成并构建工程：

   ```bash
   make app
   ```

5. 再次查看插件是否被注册：

   ```bash
   pluginkit -m -A -D -p com.apple.quicklook.preview | grep -i markdownquicklook
   ```

   正常情况下应能看到：

   ```bash
   com.markdownquicklook.app.MarkdownPreview(1.0)
   ```

### Solution: Use Xcode Debugger

#### 方法 1: 通过 Xcode 运行 (推荐)
```bash
# 1. 生成工程
make generate

# 2. 在 Xcode 中打开
open FluxMarkdown.xcodeproj

# 3. 在 Xcode 中:
#    - 选择 Markdown scheme
#    - 按 Cmd+R 运行
#    - 保持 App 运行状态

# 4. 在新终端窗口:
qlmanage -r
qlmanage -r cache
killall Finder

# 5. 测试
#    在 Finder 中选中 Tests/fixtures/feature-validation.md，按空格
```

#### 方法 2: 使用 qlmanage 命令行测试
```bash
# 直接通过 qlmanage 调用扩展（绕过注册机制）
qlmanage -p Tests/fixtures/feature-validation.md
```

### Additional Checks

#### 查看系统日志
```bash
# Terminal 1: 启动日志监控
log stream --predicate 'subsystem contains "QuickLook" OR subsystem contains "MarkdownPreview"' --level debug

# Terminal 2: 打开文件触发 Quick Look
# 在 Finder 中按空格
```

#### 验证扩展文件完整性
```bash
APP_PATH=~/Library/Developer/Xcode/DerivedData/FluxMarkdown-*/Build/Products/Debug/FluxMarkdown.app

# 检查扩展是否存在
ls -la "$APP_PATH/Contents/PlugIns/MarkdownPreview.appex/Contents/MacOS"

# 检查 Web 资源是否正确复制
ls -la "$APP_PATH/Contents/PlugIns/MarkdownPreview.appex/Contents/Resources/dist"
```

## Known Limitations

### Debug vs Release Build
- **Debug 构建**: 使用的是开发签名，系统可能有额外限制
- **Workaround**: 在 Xcode 中通过 Product → Archive 创建 Release 版本

### Sandbox Restrictions  
macOS App Sandbox 会限制文件访问权限。如果 Markdown 文件引用了本地图片，可能需要额外的 Entitlements。

## Plain Text Preview Even Though Extension Is Registered

扩展已注册、已启用，仍显示纯文本时，需要区分两个情况：Finder 没有调用我们的扩展，或扩展启动/渲染失败。`pluginkit` 的启用状态不能证明它就是本次选中的预览提供者。

“Open with Visual Studio Code”是打开文件的操作按钮，不能单凭它认定 VS Code 提供了预览。可以保留 VS Code 作为编辑器；不要把修改默认打开应用当成已确认的修复。

### 先收集只读诊断

在仓库根目录执行：

```bash
./scripts/diagnose-quicklook.sh
# 可选：查询某个文件的 Spotlight UTI；使用完整路径。
./scripts/diagnose-quicklook.sh --file "/absolute/path/to/example.md"
```

脚本输出系统/应用版本、签名检查、扩展注册数量与启用状态、保存的 QuickLook 顺序和可取得的默认应用/文件 UTI。它不读取文档内容，不输出文件路径，也不修改注册、缓存、默认应用或偏好。`unavailable` 表示该项未能取得，不代表扩展故障。

多个注册可能来自旧安装、开发构建或其他位置，数量本身不证明冲突。开发版使用 ad-hoc 签名时，Gatekeeper 的拒绝也不能单独确定 QuickLook 失效原因。

当前 `Info.plist` 已声明 `LSHandlerRank=Owner` 和 `net.daringfireball.markdown`。Owner 是文件处理角色声明，不是“Finder 一定使用这个预览器”的保证；已有诊断不能据此再次宣称问题已解决。

### 再确认是否调用扩展

```bash
log stream --style compact --predicate 'process == "MarkdownPreview"'
```

在 Finder 中对测试文件按空格：

- 完全没有本次预览的扩展启动/准备记录：优先调查系统选择、注册副本、UTI 与扩展启用状态。
- 有 `preparePreviewOfFile`，但没有 `Renderer Handshake Received`：优先调查扩展启动、资源加载和 WebKit 错误。
- 有握手且完成渲染：继续确认显示的窗口、文件及发生故障的具体内容，不再把注册作为唯一方向。

原始系统日志可能包含文件路径，请只分享与故障有关的行，并移除个人路径和文件名。先保存故障时诊断，再考虑重装或清缓存，以免丢失复现现场。
