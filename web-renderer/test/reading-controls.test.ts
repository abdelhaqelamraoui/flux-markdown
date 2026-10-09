import { updateReadingControlsLayout } from '../src/reading-controls';
import { BlockquoteCollapse } from '../src/blockquote-collapse';
beforeEach(() => {
    document.documentElement.dataset.context = 'app';
    document.body.innerHTML = '<div id="reading-controls"><div id="reading-toolbar"><div id="toc-button-container" hidden><button>Contents</button></div><div id="collapse-btn-container" hidden></div></div><div id="search-container" style="display:none"></div></div><div id="markdown-preview"></div>';
});
test('no reading tools or search leaves no reserved empty row', () => {
    updateReadingControlsLayout(); expect(document.getElementById('reading-toolbar')?.hidden).toBe(true); expect(document.documentElement.dataset.readingControls).toBe('false');
});
test('search expansion reserves its measured height in addition to toolbar', () => {
    document.getElementById('toc-button-container')!.hidden = false; const chrome = document.getElementById('reading-controls')!;
    chrome.getBoundingClientRect = jest.fn(() => ({ height: 44 } as DOMRect)); updateReadingControlsLayout();
    expect(document.documentElement.style.getPropertyValue('--reading-controls-height')).toBe('44px');
    document.getElementById('search-container')!.style.display = 'flex'; chrome.getBoundingClientRect = jest.fn(() => ({ height: 98 } as DOMRect)); updateReadingControlsLayout();
    expect(document.documentElement.style.getPropertyValue('--reading-controls-height')).toBe('98px');
    document.documentElement.dataset.context = 'finder'; updateReadingControlsLayout(); expect(document.documentElement.dataset.readingControls).toBe('false');
    expect(document.documentElement.style.getPropertyValue('--reading-controls-height')).toBe('0px');
});
test('blockquote controls only appear with targets and expose expanded state', () => {
    const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview'); bc.setInitialState(false);
    expect(document.getElementById('collapse-btn-container')!.hidden).toBe(true);
    document.getElementById('markdown-preview')!.innerHTML = '<blockquote>Quote</blockquote>'; bc.setInitialState(false);
    expect(document.getElementById('collapse-btn-container')!.hidden).toBe(false); expect(document.querySelector('.blockquote-collapse-toggle')?.getAttribute('aria-expanded')).toBe('true');
    bc.setInitialState(true); bc.setInitialState(true); expect(document.querySelectorAll('.blockquote-placeholder')).toHaveLength(1);
    expect(document.querySelector('.blockquote-collapse-toggle')?.getAttribute('aria-expanded')).toBe('false');
});
