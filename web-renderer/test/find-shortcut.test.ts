import '../src/index';

test('Cmd+F repeatedly opens/focuses search, finds text, and Escape closes it', async () => {
    HTMLElement.prototype.scrollIntoView = jest.fn();
    document.body.innerHTML = '<div id="markdown-preview"></div><div id="toc-container"></div><div id="search-container"></div>';
    window.renderSource('Alpha appears twice.', 'light');
    window.showSearch();
    expect(document.getElementById('search-container')!.style.display).toBe('flex');
    await window.renderMarkdown('# Alpha\n\nAlpha appears twice.', {context: 'quicklook'});
    const container = document.getElementById('search-container')!;
    const input = container.querySelector<HTMLInputElement>('input.search-input')!;
    window.hideSearch();
    for (let i = 0; i < 2; i++) {
        document.dispatchEvent(new KeyboardEvent('keydown', {key: 'f', metaKey: true, bubbles: true, cancelable: true}));
        expect(container.style.display).toBe('flex');
        expect(document.activeElement).toBe(input);
    }
    input.value = 'Alpha';
    input.dispatchEvent(new Event('input', {bubbles: true}));
    expect(document.querySelectorAll('#markdown-preview .search-highlight')).toHaveLength(2);
    input.dispatchEvent(new KeyboardEvent('keydown', {key: 'Escape', bubbles: true, cancelable: true}));
    expect(container.style.display).toBe('none');
    expect(document.querySelectorAll('#markdown-preview .search-highlight')).toHaveLength(0);
});
