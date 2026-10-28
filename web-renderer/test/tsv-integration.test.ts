jest.mock('mermaid', () => ({ initialize: jest.fn(), render: jest.fn() }));
import '../src/index';

beforeEach(() => { document.body.innerHTML = '<div id="markdown-preview"></div><div id="toc-container"></div><div id="search-container"></div>'; });
test('TSV applies theme/font/language, exports notice, and switches back to Markdown', async () => {
  await window.renderMarkdown('a\tb\npartial', {format:'tsv',isTruncated:true,theme:'dark',fontSize:18,uiLanguage:'zh'});
  expect(document.documentElement.dataset.theme).toBe('dark');
  expect(document.querySelector('#markdown-preview')?.getAttribute('style')).toContain('18px');
  expect(document.querySelector('th')?.textContent).toBe('列 1');
  expect(window.exportHTML()).toContain('tsv-truncated');
  window.renderSource('a\tb\npartial','dark',undefined,{format:'tsv',isTruncated:true});
  expect(document.querySelector('.tsv-truncated')).not.toBeNull();
  expect(document.querySelector('pre')?.textContent).toBe('a\tb\npartial');
  await window.renderMarkdown('# Markdown', {uiLanguage:'en'});
  expect(document.querySelector('h1')?.textContent).toBe('Markdown');
  expect(document.querySelector('.tsv-truncated')).toBeNull();
});
test('TSV suppresses Markdown interpretation and stays within cell budget', async () => {
  const row = Array(100).fill('<img src=x> $a$').join('\t');
  await window.renderMarkdown(Array(201).fill(row).join('\n'), {format:'tsv'});
  expect(document.querySelectorAll('td')).toHaveLength(20000);
  expect(document.querySelector('img, .katex, .mermaid')).toBeNull();
  expect(document.querySelector('.tsv-truncated')).not.toBeNull();
});
