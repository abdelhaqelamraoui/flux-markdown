jest.mock('mermaid', () => ({initialize: jest.fn(), render: jest.fn().mockResolvedValue({svg: '<svg/>'})}));
import '../src/index';

describe('audit regressions', () => {
 beforeEach(() => { document.body.innerHTML = '<div id="markdown-preview"></div>'; });
 test('raw HTML preserves executable event handler', async () => {
   await window.renderMarkdown('<img src="missing.png" onerror="window.__auditExecuted = true">');
   const img = document.querySelector('img')!;
   expect(img.getAttribute('onerror')).toBeNull();
   img.dispatchEvent(new Event('error'));
   expect((window as any).__auditExecuted).not.toBe(true);
 });
 test('older async math render overwrites newer document', async () => {
   const older = window.renderMarkdown('# OLD\n\n$x$', { enableKatex: true });
   const newer = window.renderMarkdown('# NEW', { enableKatex: false });
   await Promise.all([older, newer]);
   expect(document.querySelector('#markdown-preview h1')?.textContent).toBe('NEW');
 });
 test('disabling katex loses enabled emoji for one render', async () => {
   await window.renderMarkdown('$x$ :smile:', {enableKatex: true, enableEmoji: true});
   await window.renderMarkdown(':smile:', {enableKatex: false, enableEmoji: true});
   expect(document.getElementById('markdown-preview')?.textContent).not.toContain(':smile:');
 });
});

test('source mode invalidates pending preview work', async () => {
 document.body.innerHTML = '<div id="markdown-preview"></div>';
 const pending = window.renderMarkdown('```mermaid\ngraph TD; A-->B\n```');
 window.renderSource('# source', 'light');
 await pending;
 expect(document.getElementById('markdown-preview')?.classList.contains('source-mode')).toBe(true);
 expect(document.getElementById('markdown-preview')?.textContent).toContain('# source');
});

test('passive HTML, task lists and math styling survive sanitization', async () => {
 document.body.innerHTML = '<div id="markdown-preview"></div>';
 await window.renderMarkdown('<details><summary>More</summary><table><tr><td>ok</td></tr></table></details>\n\n- [x] task\n\n$\\frac{a}{b}$');
 expect(document.querySelector('details summary')?.textContent).toBe('More');
 expect(document.querySelector('input[disabled][type=checkbox]')).not.toBeNull();
 expect(document.querySelector('.katex [style]')).not.toBeNull();
});

test('active HTML and unsafe URLs are removed', async () => {
 document.body.innerHTML = '<div id="markdown-preview"></div>';
 await window.renderMarkdown('<iframe srcdoc="x"></iframe><svg onload="alert(1)"></svg><a href="javascript:alert(1)">x</a><style>body{display:none}</style>');
 expect(document.querySelector('iframe, style, [onload], [href^="javascript:"]')).toBeNull();
});

import { sanitizeDiagramHTML } from '../src/safe-html';
test('generated SVG links are safe while Mermaid HTML labels survive', () => {
 const root = document.createElement('div');
 root.innerHTML = sanitizeDiagramHTML('<svg xmlns="http://www.w3.org/2000/svg"><a href="javascript:alert(1)"><text>link</text></a><foreignObject><div xmlns="http://www.w3.org/1999/xhtml" onmouseover="alert(1)">Label</div></foreignObject></svg>');
 expect(root.querySelector('a')?.hasAttribute('href')).toBe(false);
 expect(root.querySelector('[onmouseover]')).toBeNull();
 expect(root.querySelector('foreignObject div')?.textContent).toBe('Label');
});
