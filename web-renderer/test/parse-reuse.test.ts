jest.mock('mermaid', () => ({initialize: jest.fn(), render: jest.fn()}));
import MarkdownIt from 'markdown-it';
import '../src/index';
test('one parse supplies both outline and rendered source positions', async () => {
 document.body.innerHTML = '<div id="markdown-preview"></div><div id="toc-container"></div>';
 const parse = jest.spyOn(MarkdownIt.prototype, 'parse');
 await window.renderMarkdown('---\ntitle: Test\n---\n# One\n\n## Two');
 expect(parse).toHaveBeenCalledTimes(1);
 expect(document.querySelector('h1')?.dataset.sourceLine).toBe('4');
 expect(document.querySelector('h2')?.id).toBe('two');
 parse.mockRestore();
});
