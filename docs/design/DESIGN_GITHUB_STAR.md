# GitHub Star 支持入口

用户希望在软件中一键前往 GitHub Star 支持项目。推荐方案在欢迎页、帮助菜单，以及 App/QuickLook 功能指南中提供星形入口；日常阅读工具栏不增加常驻推广按钮。

## 交互选择

轻量方案直接打开 https://github.com/xykong/flux-markdown ，文案说明“在 GitHub 页面点击 Star 支持项目”。浏览器打开成功不等于已点赞，因此不显示已点赞状态或虚构数量。原生浏览器打开失败时提供复制链接；QuickLook 使用现有可信 XPC 服务的固定仓库动作。

另一方案是在 App 中接入 GitHub 授权后调用用户的 Starring 写接口，需要 OAuth 应用配置、令牌存储及退出登录等账号生命周期；不能通过普通链接直接替用户完成 Star。依据：https://docs.github.com/en/rest/activity/starring 。用户后续要求参考社区实践并以操作方便为原则，已选择浏览器直达方案。

## 验收标准

各入口目标为同一个官方仓库，文案不误导为已经完成点赞；不自动弹窗、不请求令牌、不向 GitHub 发送 Star 写请求（轻量方案）。原生入口覆盖现有五种语言，功能指南覆盖其现有语言。检查菜单/欢迎页及指南深浅主题，确认 Star 入口可用且不会挤压正文。验证期间只检查页面打开，不实际修改账号的 Star 状态。


## 实际案例与决定

2026-10-12 查看了以下一手实现，注意区分 Star 与普通 GitHub 链接：

- [MarkText 官网](https://marktext.me/)的 Star on GitHub 按钮就是仓库根地址链接；[应用帮助菜单源码](https://github.com/marktext/marktext/blob/develop/packages/desktop/src/main/menu/templates/help.ts)使用 shell.openExternal 打开仓库、赞助及反馈页面。
- [Maccy 关于页](https://github.com/p0deje/Maccy/blob/master/Maccy/About.swift)提供 Website / GitHub / Support 外部链接，不将打开仓库伪装成已经 Star。
- [LocalSend 关于页](https://github.com/localsend/localsend/blob/main/app/lib/pages/about/about_page.dart)显式使用外部应用打开 GitHub 仓库。
- [GitHub 官方说明](https://docs.github.com/en/get-started/exploring-projects-on-github/saving-repositories-with-stars)的操作是打开仓库后点击右上方 Star。已登录默认浏览器时，本方案通常只需“应用入口 → GitHub Star”两次点击；未登录时由 GitHub 完成登录。

这些案例支持外部浏览器方案，并不能证明所有桌面软件都使用同一种方式。本项目采用明确 Star 文案、直接打开仓库、无额外确认页；不嵌入第三方按钮脚本，不获取账号令牌，也不把点击入口计作成功点赞。

## QuickLook 实机回归

2026-10-12 在 Finder QuickLook 功能指南点击 Star，原始 NSWorkspace.open 返回 FAILED。验收要求：通过保留签名、同用户和可执行路径校验的 XPC 服务打开固定仓库，不接受调用者传入任意 URL，不扩展沙盒权限；实机点击后必须确认启动成功。

## 验证结果

- 渲染器入口、现有帮助面板回归共 22 项通过；原生 GitHubStar 和 SearchLaunchPolicy 共 4 项通过。TypeScript/Vite 构建和本地 Release 构建成功。
- 欢迎页、App 功能指南、Finder QuickLook 功能指南均已实机点击并确认默认浏览器的地址为官方仓库。QuickLook 修正后日志 `GitHub repository browser handoff: SUCCESS`（2026-10-12 20:37:50）。
- 欢迎页及深浅主题功能指南截图确认按钮完整可见，无正文遮挡。
- 安装预览版 `1.35.547-dev-20261012-203651` 到 `/Applications/FluxMarkdown.app`，安装脚本确认默认编辑器偏好保留。实现验收时没有发布正式版本、没有修改 GitHub Star 状态。后续已随 1.36.556 发布，详见 [发布验证记录](../release/RELEASE_1.36.556.md)。
- 本机 Xcode 27 验证使用 macOS 12 deployment override；项目声明的 macOS 11 最低版本未改。
