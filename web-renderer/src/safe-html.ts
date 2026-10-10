import DOMPurify from 'dompurify';

/** Documents may contain presentation HTML, never executable page content. */
export function sanitizeDocumentHTML(html: string): string {
    return DOMPurify.sanitize(html, {
        USE_PROFILES: { html: true, svg: true, mathMl: true },
        FORBID_TAGS: ['style', 'script', 'iframe', 'object', 'embed', 'form', 'button', 'textarea', 'select', 'base', 'link', 'meta', 'foreignObject'],
        FORBID_ATTR: ['srcdoc', 'name', 'autofocus'],
        ADD_URI_SAFE_ATTR: ['data-source-line', 'data-source-line-end'],
        ALLOWED_URI_REGEXP: /^(?:(?:https?|mailto|local-md|file):|[^a-z]|[a-z+.-]+(?:[^a-z+.-:]|$))/i,
    });
}

/** Diagram engines also embed user-provided links; sanitize their SVG output. */
export function sanitizeDiagramHTML(html: string): string {
    return DOMPurify.sanitize(html, {
        USE_PROFILES: { html: true, svg: true, svgFilters: true, mathMl: true },
        ADD_TAGS: ['foreignobject'],
        HTML_INTEGRATION_POINTS: { foreignobject: true, 'annotation-xml': true },
        FORBID_TAGS: ['script', 'iframe', 'object', 'embed', 'form', 'input', 'button', 'base', 'link', 'meta'],
        FORBID_ATTR: ['srcdoc', 'autofocus'],
    });
}
