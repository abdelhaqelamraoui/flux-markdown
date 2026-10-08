# Change: 通过 URL 按源码行号或标题跳转

## Why

[#52](https://github.com/xykong/flux-markdown/issues/52) 请求从终端或其他工具直接打开长文档中的指定位置。当前 URL handler 只读取 path，但渲染器已有源码行范围和标题锚点基础。

## What Changes

- `markdownpreview://open?path=...&line=N` 支持从 1 开始的源码行号，范围对应原始文件，包含 front matter。
- 同时支持 URL fragment 标题锚点；有效 line 优先，line 无效时允许有效 fragment，二者无效则保持现有行为。
- 找到覆盖该行的块；空白行定位到下一块，文件末尾或越界行定位到最后可定位块。
- 显式目标优先于历史滚动恢复；没有目标时保持现有行为。
- 已打开的文件也能定位；请求按文件及渲染版本隔离，一次消费，过期渲染不能跳错文档。

## Impact

- Affected specs: 新增 `position-navigation`。
- Affected code: URL handler、PendingAnchorStore/位置请求存储、MarkdownWebView、renderer 行映射和定位 API、链接导航测试。
- 标准 Markdown 链接和导出保持现有行为。

## Review status

本次授权范围是整理需求提案。待审核后实施。
