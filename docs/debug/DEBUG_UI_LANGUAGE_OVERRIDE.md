# 界面语言与系统语言不一致

## 初始状态（2026-10-08）

- 用户报告 macOS 升级后 FluxMarkdown 界面语言不正确。
- 调查代码版本：`ec85256`；已安装应用：`1.34.475-dev-20260817-182514`。
- 系统 `AppleLanguages` 为 `zh-Hans-CN`。
- 共享偏好文件的 `uiLanguage` 为 `de`，应用域 `com.xykong.Markdown` 的 `AppleLanguages` 也为 `de`。
- 实际设置窗口标题为 `FluxMarkdown-Einstellungen`，语言选项勾选 `Deutsch`。

## 诊断

应用显式语言偏好覆盖系统语言，当前显示的是德语。现有证据不能确定偏好何时、为何变成德语，也不能据此认定为 macOS 升级造成的本地化代码缺陷。

`Sources/Shared/LocalizationManager.swift` 在启动时读取应用偏好，显式语言通过 `AppleLanguages` 持久化；选择 `system` 会删除应用域语言覆盖。AppKit 的菜单语言在进程启动时确定，因此修正偏好后需要重启应用。

## 修复前定义的验收标准

1. 在应用设置中选择“跟随系统”，共享文件的 `uiLanguage` 变为 `system`。
2. 应用域不再保存 `AppleLanguages` 覆盖，系统首选语言保持 `zh-Hans-CN`。
3. 重启应用后，设置窗口与原生工具栏显示中文。
4. 不修改其他应用偏好或 Markdown 文档。

## 验证结果

- 通过已安装应用设置界面将语言从 `Deutsch` 切换为 `系统默认`，随后使用应用内重启按钮。
- 重启后读取共享偏好：`uiLanguage=system`。
- 重启后读取应用域偏好：`AppleLanguages` 已移除；系统语言仍为 `zh-Hans-CN`。注意 `UserDefaults` 的磁盘写入有延迟，验证应在重启后进行。
- Accessibility 树与设置窗口截图确认：标题为 `FluxMarkdown设置`，显示“主题”“语言”“整个应用的界面语言”，并勾选“系统默认”。
- 欢迎界面显示“打开 Markdown 文件或拖放至此处以开始。”。
- 重新打开重启前的文档，工具栏确认显示“重新加载文件”“缩小”“重置缩放”“放大”“显示帮助”“显示源码”。
- 本次修复仅通过应用自身设置恢复语言偏好，不改动本地化实现，不需要重新构建或安装。

## 再次出现时的处理

打开应用设置（`⌘,`）→ 外观 → 语言 → 系统默认，然后按提示重启应用。应同时检查共享 `uiLanguage` 和应用域 `AppleLanguages`；只删除后者会在下次启动时被显式语言偏好重新写入。
