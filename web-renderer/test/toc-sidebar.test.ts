import type {HeadingNode} from '../src/outline';
import {TableOfContents} from '../src/table-of-contents';

beforeAll(() => {
    Object.defineProperty(window,'IntersectionObserver',{writable:true,value:class { observe() {} disconnect() {} }});
});

test('wide contents docks without overlap, remembers closure, narrows, and hides for Finder', () => {
    document.body.innerHTML = '<div id="toc-container"></div><div id="markdown-preview"></div>';
    Object.defineProperty(window,'innerWidth',{configurable:true,value:1100});
    document.documentElement.setAttribute('data-context','app');
    const toc = new TableOfContents('toc-container');
    const headings: HeadingNode[] = [{level:1,text:'Title',id:'title',children:[]}];
    toc.render(headings);
    expect(document.documentElement.dataset.tocDocked).toBe('true');
    expect(document.querySelector('.toc-nav')?.classList.contains('visible')).toBe(true);
    toc.hide(); toc.render(headings);
    expect(document.documentElement.dataset.tocDocked).toBe('false');
    expect(document.querySelector('.toc-nav')?.classList.contains('visible')).toBe(false);
    toc.show();
    Object.defineProperty(window,'innerWidth',{configurable:true,value:700});
    window.dispatchEvent(new Event('resize'));
    expect(document.documentElement.dataset.tocDocked).toBe('false');
    expect(document.querySelector('.toc-nav')?.classList.contains('visible')).toBe(true);
    document.documentElement.setAttribute('data-context','finder'); toc.render(headings);
    expect(document.documentElement.dataset.tocDocked).toBe('false');
    expect((document.getElementById('toc-container') as HTMLElement).style.display).toBe('none');
    toc.render([]);
    expect(document.documentElement.dataset.tocDocked).toBe('false');
    toc.dispose();
});
