import '../src/index';

describe('Issue #51: bare URL links', () => {
    beforeEach(() => {
        document.body.innerHTML = '<div id="markdown-preview"></div><div id="toc-container"></div><div id="search-container"></div>';
    });
    const urls = [
        'https://caddyserver.com/docs/',
        'https://docker-py.readthedocs.io/',
        'https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks',
        'https://github.com/dokku/dokku',
        'https://github.com/spf13/cobra',
    ];
    test.each(['app', 'quicklook'] as const)('recognizes the reported references in %s', async context => {
        await window.renderMarkdown('## 8. Useful References\n\n' + urls.map(url => '- Reference: ' + url).join('\n'), {context});
        const links = document.querySelectorAll<HTMLAnchorElement>('#markdown-preview a');
        expect(Array.from(links, link => link.getAttribute('href'))).toEqual(urls);
    });
    test('does not include trailing punctuation or linkify code', async () => {
        await window.renderMarkdown('See https://example.com/docs.\n\n`https://inline.example.com`\n\n```text\nhttps://code.example.com\n```');
        expect(Array.from(document.querySelectorAll('#markdown-preview a'), a => a.getAttribute('href'))).toEqual(['https://example.com/docs']);
        expect(document.querySelector('#markdown-preview code a')).toBeNull();
    });
    test('preserves explicit labels, autolinks and safe link validation', async () => {
        await window.renderMarkdown('[Caddy](https://caddyserver.com/docs/) <https://example.com> [bad](javascript:alert%281%29)');
        const links = document.querySelectorAll('#markdown-preview a');
        expect(links).toHaveLength(2);
        expect(links[0].textContent).toBe('Caddy');
        expect(document.querySelector('a[href^="javascript:"]')).toBeNull();
    });
    test('routes a generated link through the native bridge', async () => {
        const postMessage = jest.fn();
        const previous = window.webkit;
        Object.defineProperty(window, 'webkit', {configurable: true, value: {messageHandlers: {linkClicked: {postMessage}}}});
        try {
            await window.renderMarkdown('https://example.com/docs');
            const link = document.querySelector<HTMLAnchorElement>('#markdown-preview a');
            expect(link).not.toBeNull();
            link!.click();
            expect(postMessage).toHaveBeenCalledWith('https://example.com/docs');
        } finally {
            Object.defineProperty(window, 'webkit', {configurable: true, value: previous});
        }
    });
});
