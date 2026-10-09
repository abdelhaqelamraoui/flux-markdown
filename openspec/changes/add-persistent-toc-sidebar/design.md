## Decisions

- 优先复用网页目录，避免为 App 和 QuickLook 维护两套不同的标题索引。
- 内容视口宽度达到 900 CSS px 时显示右侧停靠目录，首版固定 240 px；更窄时使用可关闭浮层。最终尺寸需截图验证，确保正文不挤压。
- 在当前视图会话保持用户的目录显隐选择；重载、主题切换和窗口大小变化只改变布局，不擅自重新打开用户已关闭的目录。
- 正文与目录采用布局分栏，不通过覆盖层伪造常驻；标题更新、当前标题指示和锚点导航复用原实现。
- 切换布局时保持阅读位置。无标题时不预留空白侧栏。
- Finder 紧凑预览和打印/导出不保留侧栏占位；缩放、深色模式及键盘焦点必须一起验证。

## Validation

覆盖长文档、无标题、嵌套标题、900 px 边界、手动关闭后重载、主题切换、App/QuickLook 全屏、紧凑 Finder、缩放和导出。截图检查正文与按钮不重叠；检查键盘可操作性和目录锚点定位。

## Design refinement — 2026-10-10

完整产品方案见 [#50 目录侧栏设计](../../../docs/design/DESIGN_ISSUE_50_CONTENTS_SIDEBAR.md)。本轮是设计细化，新增交互尚未全部实现。

- 同时解决目录遮挡和浮动按钮遮挡：顶部工具区预留高度，目录及引用块按钮统一入口；搜索展开额外占位。
- 停靠偏好与临时浮层状态分离。宽转窄关闭浮层，窄窗口的打开/关闭不覆盖宽窗口偏好；返回宽窗口恢复偏好。
- 窄窗口选择章节后收起浮层；提供点击正文/入口关闭。主应用支持 Esc；QuickLook 保留系统键盘行为。
- 标题导航和布局切换保留阅读块及顶部偏移。长标题、活动项追踪、多文档隔离与输出布局纳入验收。
- 首版固定右侧 240 CSS px；不新增宽度拖拽、左右切换、跨次启动偏好或全局快捷键。

## Rendering choice verified in the native app

The grid reserves the 240 CSS px contents column. Its navigation panel is fixed to
the same column's viewport position, with independent internal scrolling. This
avoids the observed full-screen sticky-layer paint problem in WebKit. Explicit
`#markdown-preview` margins preserve centered reading width despite upstream
Markdown CSS resets. The final native full-screen screenshot validates both panes.

## Approved user feedback: compact shared tools and floating search

The user rejected the extra directory row and reserved search row. Controls now
share the native top area whenever their measured widths fit. A compact row is
used only when necessary. Search is centered over the document column, floats
without changing document height or reading position, and navigation scroll margins
clear its temporary overlay. Wide-view first content starts at 80 CSS px (was 155).
