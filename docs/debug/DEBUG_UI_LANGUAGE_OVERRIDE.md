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

## 升级关联与 API 调查

- 本机当前系统：macOS `27.0.1`，build `26A434`。用户确认异常在系统升级后出现；没有升级前的语言偏好快照，不能确定写入时间。
- 应用语言控制逻辑由提交 `0e247bd`（2026-04-28，#34）引入。启动时 `bootstrap` 读取共享偏好并写入应用域 `AppleLanguages`，随后通过替换 `Bundle.main` 类型直接路由到指定语言资源。
- 默认值为 `system`。当前仓库中设置界面的德语按钮会写入 `de`；旧 App Group 迁移也可能复制已有的 `uiLanguage`。未发现根据操作系统版本自动选择德语的分支。
- `uiLanguage` 是应用自定义的共享 plist 字段。仅发生系统语言解析错误或应用域 `AppleLanguages` 改变，不能直接解释这个字段为何也为 `de`。仍需考虑旧偏好恢复/迁移、应用写入或外部修改；现有证据不能确定是哪一种，也不证明用户误操作。
- 本次调查没有找到 Apple 确认的、与 macOS 27.0.1 和本项目配置一致的 API 回归。

### 官方资料与相似报告

- [Apple：User Defaults 的域和搜索顺序](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UserDefaults/AboutPreferenceDomains/AboutPreferenceDomains.html)：应用域优先于全局域，`AppleLanguages` 存储首选语言。这能解释应用显式覆盖中文系统语言的行为。
- [Apple：Mac 系统语言与单个应用语言](https://support.apple.com/guide/mac-help/change-the-system-language-mh26684/27/mac/27)：单个应用可以使用不同于系统的语言，变更后可能需要退出再打开。
- [Apple：语言与地区设置](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/SpecifyingPreferences/SpecifyingPreferences.html)：Mac 应用的语言变更在重启应用后生效。
- [用户报告：macOS Tahoe, often text in another language](https://www.reddit.com/r/mac/comments/1qxk0vk/macos_tahoe_often_text_in_another_language/)：报告人设置荷兰语/英语，却在 iMovie 中看到德语、App Store 中看到其他语言。属于相似症状的个案，帖子没有确认原因，系统版本也与本机不同。

### 代码层面的后续方向

若继续定位复发，应记录语言偏好写入来源，以及启动时的共享偏好、应用域覆盖和 Bundle 解析结果，并补充显式语言与系统默认切换的重启回归测试。当前运行时替换 Bundle 类型及启动时写入语言偏好的实现也需要纳入系统升级兼容性测试。不能在缺少复现依据时自动清除所有非系统语言偏好，这会覆盖用户合法的语言选择。
