/** Shared, measured layout for the reading controls (below native window tools). */
declare global { interface Window { __fluxLang?: string; } }
const labels = {
    en: { tools: 'Reading controls', contents: 'Contents', close: 'Close contents', collapse: 'Collapse blockquotes', expand: 'Expand blockquotes' },
    zh: { tools: '阅读工具', contents: '目录', close: '关闭目录', collapse: '折叠引用块', expand: '展开引用块' },
    de: { tools: 'Lesewerkzeuge', contents: 'Inhalt', close: 'Inhalt schließen', collapse: 'Zitate einklappen', expand: 'Zitate ausklappen' },
    fr: { tools: 'Outils de lecture', contents: 'Sommaire', close: 'Fermer le sommaire', collapse: 'Replier les citations', expand: 'Déplier les citations' }
};
export function readingLabels() {
    const language = (window.__fluxLang || navigator.language || 'en').split('-')[0];
    return labels[language as keyof typeof labels] || labels.en;
}

export function updateReadingControlsLayout(): void {
    const root = document.documentElement;
    const controls = document.getElementById('reading-controls');
    if (!controls) return;
    const compact = root.dataset.context === 'finder';
    const toolbar = document.getElementById('reading-toolbar');
    const hasTools = ['toc-button-container', 'collapse-btn-container'].some(id => {
        const slot = document.getElementById(id);
        return slot && !slot.hidden && slot.childElementCount > 0;
    });
    if (toolbar) { toolbar.hidden = !hasTools; toolbar.setAttribute('aria-label', readingLabels().tools); }
    const search = document.getElementById('search-container');
    const hasSearch = !!search && search.style.display === 'flex';
    const visible = !compact && (hasTools || hasSearch);
    controls.hidden = !visible;
    root.dataset.readingControls = String(visible);
    const height = visible ? Math.ceil(controls.getBoundingClientRect().height) : 0;
    root.style.setProperty('--reading-controls-height', `${height}px`);
}

export class ReadingControls {
    private observer: ResizeObserver | null = null;
    private readonly update = () => updateReadingControlsLayout();
    constructor(private element: HTMLElement) {
        if (typeof ResizeObserver !== 'undefined') {
            this.observer = new ResizeObserver(this.update);
            this.observer.observe(element);
        }
        window.addEventListener('resize', this.update);
        this.update();
    }
    isMounted(): boolean { return this.element === document.getElementById('reading-controls'); }
    dispose(): void { this.observer?.disconnect(); window.removeEventListener('resize', this.update); }
}

export interface ReadingAnchor { element: HTMLElement; top: number; scrollY: number; }
export function captureReadingAnchor(): ReadingAnchor | null {
    if (window.scrollY <= 0 || typeof document.elementFromPoint !== 'function') return null;
    const preview = document.getElementById('markdown-preview');
    const bounds = preview?.getBoundingClientRect();
    if (!bounds) return null;
    const top = document.getElementById('reading-controls')?.getBoundingClientRect().bottom || 60;
    const hit = document.elementFromPoint(bounds.left + bounds.width / 2, Math.min(top + 16, window.innerHeight - 1));
    const element = hit?.closest<HTMLElement>('#markdown-preview > *');
    return element ? { element, top: element.getBoundingClientRect().top, scrollY: window.scrollY } : null;
}
export function restoreReadingAnchor(anchor: ReadingAnchor | null): void {
    if (!anchor) return;
    Promise.resolve().then(() => {
        if (!anchor.element.isConnected || Math.abs(window.scrollY - anchor.scrollY) > 1) return;
        const delta = anchor.element.getBoundingClientRect().top - anchor.top;
        if (Math.abs(delta) > 1) window.scrollBy(0, delta);
    });
}
