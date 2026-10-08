import type { HeadingNode } from './outline';

function compressMultipleHyphens(text: string): string {
    return text.replace(/-+/g, '-');
}

function unifyUnderscoreAndHyphen(text: string): string {
    return text.replace(/[_-]/g, '~');
}

function findElementByAnchor(anchorId: string): HTMLElement | null {
    const allElementsWithId = document.querySelectorAll('[id]');
    
    const exactMatch = document.getElementById(anchorId);
    if (exactMatch) return exactMatch;
    
    const level2NormalizedTarget = compressMultipleHyphens(anchorId);
    for (const element of allElementsWithId) {
        const elementId = element.getAttribute('id');
        if (elementId && compressMultipleHyphens(elementId) === level2NormalizedTarget) {
            return element as HTMLElement;
        }
    }
    
    const level3NormalizedTarget = unifyUnderscoreAndHyphen(compressMultipleHyphens(anchorId));
    for (const element of allElementsWithId) {
        const elementId = element.getAttribute('id');
        if (elementId && unifyUnderscoreAndHyphen(compressMultipleHyphens(elementId)) === level3NormalizedTarget) {
            return element as HTMLElement;
        }
    }
    
    return null;
}

export class TableOfContents {
    private container: HTMLElement;
    private isVisible: boolean = false;
    private activeId: string | null = null;
    private userVisibility: boolean | null = null;
    private hasHeadings = false;
    private observer: IntersectionObserver | null = null;
    private observeTimer: ReturnType<typeof setTimeout> | null = null;
    private readonly resizeHandler = () => this.updateLayout();

    constructor(containerId: string) {
        const element = document.getElementById(containerId);
        if (!element) {
            throw new Error(`TOC container element not found: ${containerId}`);
        }
        this.container = element;
        this.setupToggleButton();
        this.setupIntersectionObserver();
        window.addEventListener('resize', this.resizeHandler);
    }

    private setupToggleButton(): void {
        const button = document.createElement('button');
        button.className = 'toc-toggle';
        button.setAttribute('aria-label', 'Toggle Table of Contents');
        button.innerHTML = `
            <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path d="M2 4h16v2H2V4zm0 5h16v2H2V9zm0 5h16v2H2v-2z"/>
            </svg>
        `;
        button.addEventListener('click', () => this.toggle());
        this.container.appendChild(button);
    }

    private setupIntersectionObserver(): void {
        const observerOptions = {
            rootMargin: '-80px 0px -80% 0px',
            threshold: 0
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.setActiveItem(entry.target.id);
                }
            });
        }, observerOptions);

        const observeHeadings = () => {
            const headings = document.querySelectorAll('h1[id], h2[id], h3[id], h4[id], h5[id], h6[id]');
            headings.forEach(heading => {
                observer.observe(heading);
            });
        };

        this.observer = observer;
        this.observeTimer = setTimeout(observeHeadings, 100);
    }

    private setActiveItem(id: string): void {
        if (this.activeId === id) return;
        
        this.activeId = id;
        const links = this.container.querySelectorAll('.toc-link');
        links.forEach(link => {
            if (link.getAttribute('href') === `#${id}`) {
                link.classList.add('active');
            } else {
                link.classList.remove('active');
            }
        });
    }

    public render(headings: HeadingNode[]): void {
        this.hasHeadings = headings.length > 0;
        if (headings.length === 0) {
            this.updateLayout();
            this.container.style.display = 'none';
            return;
        }

        this.container.style.display = 'block';

        const nav = document.createElement('nav');
        nav.className = 'toc-nav';
        nav.setAttribute('aria-label', 'Table of Contents');

        const title = document.createElement('div');
        title.className = 'toc-title';
        title.textContent = 'Contents';
        nav.appendChild(title);

        const list = this.renderList(headings);
        nav.appendChild(list);

        const existingNav = this.container.querySelector('.toc-nav');
        if (existingNav) {
            this.container.replaceChild(nav, existingNav);
        } else {
            this.container.appendChild(nav);
        }

        this.attachClickHandlers();
        this.observer?.disconnect();
        document.querySelectorAll('#markdown-preview h1[id], #markdown-preview h2[id], #markdown-preview h3[id], #markdown-preview h4[id], #markdown-preview h5[id], #markdown-preview h6[id]')
            .forEach(heading => this.observer?.observe(heading));
        this.updateLayout();
    }

    private renderList(headings: HeadingNode[]): HTMLElement {
        const ul = document.createElement('ul');
        ul.className = 'toc-list';

        headings.forEach(heading => {
            const li = document.createElement('li');
            li.className = 'toc-item';

            const link = document.createElement('a');
            link.className = 'toc-link';
            link.href = `#${heading.id}`;
            link.textContent = heading.text;
            link.dataset.level = heading.level.toString();
            li.appendChild(link);

            if (heading.children.length > 0) {
                const childList = this.renderList(heading.children);
                li.appendChild(childList);
            }

            ul.appendChild(li);
        });

        return ul;
    }

    private attachClickHandlers(): void {
        const links = this.container.querySelectorAll('.toc-link');
        links.forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const href = (e.target as HTMLAnchorElement).getAttribute('href');
                if (href) {
                    const targetId = href.substring(1);
                    const targetElement = findElementByAnchor(targetId);
                    if (targetElement) {
                        targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
                        const actualId = targetElement.getAttribute('id');
                        if (actualId) {
                            this.setActiveItem(actualId);
                        }
                    }
                }
            });
        });
    }

    public updateLayout(): void {
        const wasDocked = document.documentElement.dataset.tocDocked === 'true';
        const preview = document.getElementById('markdown-preview');
        const bounds = preview?.getBoundingClientRect();
        const hit = bounds && typeof document.elementFromPoint === 'function'
            ? document.elementFromPoint(bounds.left + bounds.width / 2, Math.min(100, window.innerHeight / 2)) : null;
        const anchor = hit?.closest<HTMLElement>('#markdown-preview > *');
        const previousTop = anchor?.getBoundingClientRect().top;
        const compact = document.documentElement.dataset.context === 'finder';
        const wide = window.innerWidth >= 900 && !compact;
        this.isVisible = this.hasHeadings && !compact && (this.userVisibility ?? wide);
        const docked = wide && this.isVisible;
        document.documentElement.dataset.tocDocked = String(docked);
        document.documentElement.dataset.tocAvailable = String(this.hasHeadings && !compact);
        this.container.dataset.layout = docked ? 'sidebar' : 'overlay';
        this.container.style.display = this.hasHeadings && !compact ? 'block' : 'none';
        this.container.querySelector('.toc-nav')?.classList.toggle('visible', this.isVisible);
        this.container.querySelector('.toc-toggle')?.setAttribute('aria-expanded', String(this.isVisible));
        if (wasDocked !== docked && anchor && previousTop !== undefined) {
            Promise.resolve().then(() => {
                if (!anchor.isConnected) return;
                const delta = anchor.getBoundingClientRect().top - previousTop;
                if (Math.abs(delta) > 1) window.scrollBy(0, delta);
            });
        }
    }

    public toggle(): void { this.userVisibility = !this.isVisible; this.updateLayout(); }
    public show(): void { this.userVisibility = true; this.updateLayout(); }
    public hide(): void { this.userVisibility = false; this.updateLayout(); }
    public dispose(): void {
        window.removeEventListener('resize', this.resizeHandler);
        this.observer?.disconnect();
        if (this.observeTimer) clearTimeout(this.observeTimer);
    }
}
