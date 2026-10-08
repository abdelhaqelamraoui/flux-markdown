export interface DocumentPosition { line?: number; anchor?: string }

export function findSourceLineTarget(root: HTMLElement, line: number): HTMLElement | null {
    if (!Number.isSafeInteger(line) || line < 1) return null;
    const nodes = Array.from(root.querySelectorAll<HTMLElement>('[data-source-line]'))
        .filter(node => Number.isFinite(Number(node.dataset.sourceLine)));
    const covering = nodes.filter(node => {
        const start = Number(node.dataset.sourceLine);
        return start <= line && Number(node.dataset.sourceLineEnd || start) >= line;
    });
    // Prefer smaller ranges and then deeper nested blocks.
    covering.sort((a,b) => {
        const range = (el:HTMLElement) => Number(el.dataset.sourceLineEnd || el.dataset.sourceLine) - Number(el.dataset.sourceLine);
        return range(a) - range(b) || (a.contains(b) ? 1 : b.contains(a) ? -1 : 0);
    });
    if (covering.length) return covering[0];
    const following = nodes.filter(node => Number(node.dataset.sourceLine) > line)
        .sort((a,b) => Number(a.dataset.sourceLine) - Number(b.dataset.sourceLine));
    return following[0] || nodes.sort((a,b) => Number(b.dataset.sourceLine) - Number(a.dataset.sourceLine))[0] || null;
}
