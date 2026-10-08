import '../src/index';

describe('Original source position navigation', () => {
    beforeEach(() => {
        HTMLElement.prototype.scrollIntoView = jest.fn();
        document.body.innerHTML = '<div id="markdown-preview"></div><div id="toc-container"></div><div id="search-container"></div>';
    });
    test('maps original lines after front matter, including nested lists and fences', async () => {
        await window.renderMarkdown('---\ntitle: Test\n---\n\n# Heading\n\n- first\n- second\n\n```text\ncode\n```\n\nFinal paragraph.', {showLineNumbers:false});
        const root = document.getElementById('markdown-preview')!;
        expect(root.querySelector('h1')?.getAttribute('data-source-line')).toBe('5');
        expect(root.querySelector('pre')?.getAttribute('data-source-line')).toBe('10');
        expect(root.querySelector('pre')?.getAttribute('data-source-line-end')).toBe('12');
        expect(window.navigateDocumentPosition({line:11})).toBe(true);
        expect(HTMLElement.prototype.scrollIntoView).toHaveBeenLastCalledWith({behavior:'auto',block:'start'});
    });
    test('selects covering, following, or final blocks without interpolating selectors', async () => {
        await window.renderMarkdown('# First\n\nParagraph\nsecond line\n\n# Last');
        const root = document.getElementById('markdown-preview')!;
        const p = root.querySelector('p')!, last = root.querySelectorAll('h1')[1];
        p.scrollIntoView = jest.fn(); last.scrollIntoView = jest.fn();
        expect(window.navigateDocumentPosition({line:4})).toBe(true);
        expect(p.scrollIntoView).toHaveBeenCalled();
        expect(window.navigateDocumentPosition({line:5})).toBe(true);
        expect(last.scrollIntoView).toHaveBeenCalled();
        expect(window.navigateDocumentPosition({line:999})).toBe(true);
        expect(window.navigateDocumentPosition({anchor:'last'})).toBe(true);
        expect(window.navigateDocumentPosition({anchor:'search-container'})).toBe(false);
    });
    test('empty content and invalid lines do not scroll', async () => {
        await window.renderMarkdown('');
        expect(window.navigateDocumentPosition({line:1})).toBe(false);
        expect(window.navigateDocumentPosition({line:-1})).toBe(false);
    });
});
