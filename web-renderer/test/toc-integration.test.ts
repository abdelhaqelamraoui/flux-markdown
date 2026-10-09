import '../src/index';
import { SearchUI } from '../src/search-ui';
import { SearchEngine } from '../src/search';

beforeEach(() => {
    Object.defineProperty(window, 'innerWidth', { configurable: true, value: 700 });
    document.body.innerHTML = '<div id="reading-controls"><div id="reading-toolbar"><div id="toc-button-container" hidden></div><div id="collapse-btn-container" hidden></div></div></div><div id="search-container"></div><div id="reading-layout"><div id="markdown-preview"></div><div id="toc-container"></div></div>';
});
test('global link bridge leaves directory clicks to directory navigation', async () => {
    await window.renderMarkdown('# One\n\n## Two', { context: 'app', theme: 'light' });
    document.querySelector<HTMLButtonElement>('.toc-toggle')!.click();
    document.getElementById('two')!.scrollIntoView = jest.fn();
    document.querySelector<HTMLAnchorElement>('.toc-link[href="#two"]')!.click();
    expect(document.querySelector<HTMLElement>('.toc-nav')!.hidden).toBe(true);
    expect(document.querySelector('[href="#two"]')!.getAttribute('aria-current')).toBe('location');
});
test('same view reload retains closed docked preference and updates tools', async () => {
    Object.defineProperty(window, 'innerWidth', { configurable: true, value: 1100 });
    await window.renderMarkdown('# One\n\n> Quote', { context: 'app' });
    document.querySelector<HTMLButtonElement>('.toc-toggle')!.click();
    await window.renderMarkdown('# Two', { context: 'app' });
    expect(document.documentElement.dataset.tocDocked).toBe('false');
    expect(document.getElementById('collapse-btn-container')!.hidden).toBe(true);
    expect(document.querySelectorAll('.toc-toggle')).toHaveLength(1);
});
test('HTML export expands collapsed quotes and omits reading controls and state', async () => {
    await window.renderMarkdown('# One\n\n> Important quote', { context: 'app', collapseBlockquotes: true });
    const output = new DOMParser().parseFromString(window.exportHTML(), 'text/html');
    expect(output.querySelector('#reading-controls')).toBeNull();
    expect(output.querySelector('#toc-container')).toBeNull();
    expect(output.documentElement.hasAttribute('data-toc-docked')).toBe(false);
    expect(output.querySelector('.blockquote-placeholder')).toBeNull();
    expect(output.querySelector('blockquote')?.style.display).not.toBe('none');
    expect(document.querySelector('blockquote')?.style.display).toBe('none');
});

test('Escape closes narrow contents before the focused search input', async () => {
    await window.renderMarkdown('# One', { context: 'app' });
    const search = new SearchUI('search-container', new SearchEngine());
    search.show();
    document.querySelector<HTMLButtonElement>('.toc-toggle')!.click();
    document.querySelector<HTMLInputElement>('.search-input')!.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true }));
    expect(document.querySelector<HTMLElement>('.toc-nav')!.hidden).toBe(true);
    expect(search.isSearchVisible()).toBe(true);
});

test('side changes retain a closed directory and current search query', async () => {
    Object.defineProperty(window, 'innerWidth', { configurable: true, value: 1100 });
    await window.renderMarkdown('# One\n\n## Two', { context: 'app', contentsSide: 'right' });
    document.querySelector<HTMLButtonElement>('.toc-toggle')!.click();
    const search = new SearchUI('search-container', new SearchEngine()); search.show();
    document.querySelector<HTMLInputElement>('.search-input')!.value = 'One';
    window.setContentsSide('left');
    expect(document.documentElement.dataset.tocSide).toBe('left');
    expect(document.querySelector<HTMLElement>('.toc-nav')!.hidden).toBe(true);
    expect(document.querySelector<HTMLInputElement>('.search-input')!.value).toBe('One');
    window.setContentsSide('invalid');
    expect(document.documentElement.dataset.tocSide).toBe('right');
});
