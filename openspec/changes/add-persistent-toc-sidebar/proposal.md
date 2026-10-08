# Change: 可常驻且不遮挡正文的目录侧栏

## Why

[#50](https://github.com/xykong/flux-markdown/issues/50) 和附议指出当前目录浮层及按钮遮挡正文，长文档无法保持目录可见。

## What Changes

- App 和展开 QuickLook 的宽窗口使用正文旁的目录侧栏，正文为其留出空间。
- 窄窗口回退可折叠浮层；Finder 紧凑预览维持现有简洁布局。
- 目录显隐在同一视图会话内记忆，重载不重置；用户可以关闭侧栏。
- 与目录有关的浮动按钮整合到面板控制区，避免压住正文。
- HTML/PDF 导出和打印隐藏目录控件并恢复正文宽度。

## Impact

- Affected specs: 新增 `toc-layout`。
- Affected code: TableOfContents、renderer 页面布局/CSS、HTML 容器、目录与导出测试。
- 首版不新增跨进程持久化偏好或原生侧栏，复用共享 renderer。

## Review status

用户于 2026-10-09 明确授权按照现有方案实现全部功能和修复。
