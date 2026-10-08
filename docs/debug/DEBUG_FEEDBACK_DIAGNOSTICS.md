# 设置历史与反馈诊断验证

## 背景和验收

语言异常调查只能看到当前德语偏好，缺少修改来源。对应已批准提案：`openspec/changes/add-feedback-diagnostics/`。

验收包括：最近 200 条设置变化和 20 条启动快照不按时间过期，来源区分，默认值记录，滑块合并，正常重启保留，字段白名单，报告预览/排除/复制/保存/清空，以及 GitHub 表单预填与长度降级。历史有数量及 256 KiB 大小限制，不能保证完整复现。

## 实现

主应用唯一写入者；独立 JSON 文件与串行队列，原子写入并使用 0600 文件权限。设置路径通过 `AppearancePreference` 接入，迁移路径通过回调记录。启动、前台激活、每 10 秒和反馈前观察共享设置外部变化。时间戳用于排序，外部来源表示观察而不是已知操作者。

报告记录启动前应用域语言覆盖及启动后有效语言，避免 bootstrap 覆盖原值后丢失诊断证据。报告与磁盘加载均重新验证字段和值；自动采集不包含文档内容、文件名、路径、滚动位置或原始日志。

## 测试进展

- 新增测试先执行失败，确认缺少 `SettingsHistoryStore` 等实现。
- 第一轮新增 9 项测试通过，主应用及扩展编译通过。
- 当前 Xcode 的 macOS SDK 仅支持 12.0 及以上部署目标；验证命令临时传入 `MACOSX_DEPLOYMENT_TARGET=12.0`。项目原有 11.0 配置未修改，故本次不声称已验证 macOS 11。
- 追加历史文件版本字段过滤与字体 0 默认哨兵的失败用例后修复，最终相关测试结果见下方。
- 原生中文反馈窗口实际检查通过：两类帮助菜单入口、可编辑诊断、排除诊断后的导出仅含问题描述、包含诊断的导出包含白名单环境及设置。导出文件不含路径。
- 实际 GitHub Bug 表单的版本和问题描述预填通过；Feature Request 表单成功打开。未提交任何测试 Issue。远程当前表单还没有 diagnostics 字段，新增字段的线上验证留到合入默认分支后执行。
- 使用仓库安装脚本更新本地 Debug 开发构建，应用/扩展签名验证通过，当前显示版本为 `1.34.475-dev-20261008-184159`。原安装包已在临时目录备份。
- QuickLook 运行包验证：`qlmanage -p Tests/fixtures/test-emoji.md` 启动 `/Applications/FluxMarkdown.app` 中的扩展；系统日志确认 `Loaded renderer via custom scheme` 和 `Renderer Handshake Received`。
- 五套 Localizable.strings 经 plutil 校验通过；Bug 表单 YAML 及 diagnostics 字段经 YAML 解析校验通过。

### 最终检查

最终 43 项相关测试通过：16 项 FeedbackDiagnosticsTests、18 项 SharedPreferenceStoreTests、9 项 ThemeSwitchRenderModeTests。主应用和扩展构建通过。本次只针对相关改动运行测试，不宣称整个项目测试套件通过。

## 发布依赖

新增 GitHub `diagnostics` 表单字段需要随代码一起合入远程默认分支；本地提交不会更新线上表单。无法通过 GitHub URL 自动上传附件；较长内容提供完整报告复制/导出。
