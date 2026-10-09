## 1. Proposal
- [x] 1.1 对照 #50 和现有浮层目录整理方案
- [x] 1.2 OpenSpec 严格验证
- [x] 1.3 用户审核（2026-10-09 明确授权按方案实现全部功能）

## 2. Implementation after approval
- [x] 2.1 布局模式、显隐状态和重载失败测试
- [x] 2.2 实现分栏与窄窗口回退及按钮整合
- [x] 2.3 保持标题导航、阅读位置及会话显隐选择
- [ ] 2.4 打印/导出/Finder 布局回归
- [ ] 2.5 App/QuickLook 全屏、主题、缩放和截图验证
- [ ] 2.6 用户说明、CHANGELOG 和发布后 issue 回复

## 3. 2026-10-10 design refinement (implemented; platform acceptance pending)
- [x] 3.1 整理原始诉求与附议，完成工具区、侧栏和响应式交互设计。
- [x] 3.2 分离停靠偏好和浮层状态，补齐转换测试与关闭交互。
- [x] 3.3 工具区预留布局空间，目录/引用块按钮统一入口并适配搜索栏。
- [ ] 3.4 按完整设计完成活动项、焦点和真实窗口验收。

### Verification notes — 2026-10-10

The state transitions, reserved controls, navigation and output behavior are implemented.
Browser acceptance covers 520/760/899/900/901/1100 CSS px, reduced overlap, independent
preferences, current headings, dark appearance, 100–200% zoom, HTML export, print and
compact Finder context. Native Release app docking and the visibility button were
verified. Native app full-screen layout was also verified after the fixed-panel refinement.
Native narrow-window/QuickLook coverage is still pending: the GUI
provider could not resize the test window, and qlmanage accessibility observation
returned permission_denied. These gaps do not become checked release-acceptance tasks.
See docs/debug/DEBUG_ISSUE_50_CONTENTS_SIDEBAR.md for exact evidence and limits.

## 4. User feedback: reclaim top space
- [x] 4.1 Stop allocating separate directory/search rows when controls fit in the native top area.
- [x] 4.2 Restore document-centered floating search without reflow or focus-induced scrolling.
- [x] 4.3 Verify 334 tests, six browser widths, native shared-row layout and real Alpha search (1/2).
- [x] 4.4 Rebuild/install current renderer and verify resource hashes, signatures and sandbox entitlements.

## 5. User-requested directory side
- [x] 5.1 Record the explicitly requested left/right preference and aligned entrance.
- [x] 5.2 Verify persisted native settings, live side changes and invalid-value fallback.
- [x] 5.3 Implement localized Appearance picker, app/QuickLook option propagation and same-side layouts.
- [x] 5.4 Verify geometry, navigation, search centering and native picker before installing the candidate.
