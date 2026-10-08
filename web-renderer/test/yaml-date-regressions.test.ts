import '../src/index';

describe('YAML Date values (PR #56)', () => {
    beforeEach(() => {
        document.body.innerHTML = '<div id="markdown-preview"></div><div id="toc-container"></div><div id="search-container"></div>';
    });
    test('renders dates in fields, arrays and nested objects while escaping scalar HTML', async () => {
        await window.renderMarkdown('---\ndate: 2024-01-01\nvalues:\n  - 2024-02-03\n  - null\n  - "<b>literal</b>"\n  - name: nested\n    date: 2024-03-04\n---\n\n# Content');
        const table = document.querySelector('.yaml-frontmatter')!;
        for (const value of ['2024-01-01','2024-02-03','2024-03-04','nested','<b>literal</b>']) expect(table.textContent).toContain(value);
        expect(table.querySelector('b')).toBeNull();
        expect(table.textContent).not.toContain('[object Object]');
    });
    test('cyclic YAML aliases fall back safely rather than breaking document rendering', async () => {
        await window.renderMarkdown('---\ncycle: &cycle\n  - *cycle\n---\n\n# Still visible');
        expect(document.getElementById('markdown-preview')?.textContent).toContain('Still visible');
    });
});
