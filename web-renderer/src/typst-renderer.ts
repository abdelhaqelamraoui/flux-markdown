import mathFontUrl from './assets/typst/NewCMMath-Regular.otf?url';
import textFontUrl from './assets/typst/NewCM10-Regular.otf?url';
import compilerWasmUrl from '@myriaddreamin/typst-ts-web-compiler/wasm?url';
import rendererWasmUrl from '@myriaddreamin/typst-ts-renderer/wasm?url';
import { rendererLabels } from './renderer-strings';
/**
 * Typst math rendering module.
 *
 * Two-tier architecture:
 * - QuickLook/Finder: transpile Typst→LaTeX via tex2typst, render with KaTeX
 * - Host App: compile Typst→SVG via typst.ts WASM (lazy-loaded)
 */

import { typst2tex } from 'tex2typst';

// --- Transpilation path (QuickLook) ---

export function transpileTypstToLatex(typstCode: string): string {
    return typst2tex(typstCode, { blockMathMode: true });
}

/**
 * Render a Typst math block using transpilation → KaTeX.
 * Used in QuickLook/Finder context where bundle size matters.
 */
export async function renderTypstViaTranspilation(
    typstCode: string
): Promise<string> {
    // @ts-ignore — katex has no bundled type declarations
    const katexModule = await import('katex');
    const katex = (katexModule as any).default ?? katexModule;
    const latex = transpileTypstToLatex(typstCode);
    return katex.renderToString(latex, {
        displayMode: true,
        throwOnError: false,
        output: 'htmlAndMathml',
    });
}

// --- Native WASM path (Host App) ---

type TypstInstance = InstanceType<typeof import('@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs').TypstSnippet>;
let typstInitPromise: Promise<TypstInstance> | null = null;
let nativeQueue: Promise<unknown> = Promise.resolve();

async function getTypstInstance(): Promise<TypstInstance> {
    if (!typstInitPromise) {
        typstInitPromise = (async () => {
            const { TypstSnippet } = await import(
                '@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs'
            );
            const $typst = new TypstSnippet();
            $typst.use(TypstSnippet.disableDefaultFontAssets(), TypstSnippet.preloadFonts([mathFontUrl, textFontUrl]));
            $typst.setCompilerInitOptions({ getModule: () => compilerWasmUrl });
            $typst.setRendererInitOptions({ getModule: () => rendererWasmUrl });
            return $typst;
        })().catch(error => { typstInitPromise = null; throw error; });
    }
    return typstInitPromise;
}

/**
 * Render a Typst math block natively to SVG via WASM.
 * Used in Host App context where full fidelity is desired.
 */
export async function renderTypstViaNative(
    typstCode: string
): Promise<string> {
    const operation = nativeQueue.then(async () => {
        try {
            const $typst = await getTypstInstance();
            const mainContent = `#set page(width: auto, height: auto, margin: 0pt)\n$ ${typstCode} $`;
            const svg = await $typst.svg({ mainContent });
            // Typst includes a global `svg { fill: none }` stylesheet and an
            // invisible HTML selection layer. Keep this static SVG independent
            // of other diagrams; scoped glyph rules live in typst.css.
            const template = document.createElement('template');
            template.innerHTML = svg;
            const graphicElement = template.content.querySelector('svg');
            if (!graphicElement) throw new Error('Typst returned no SVG');
            graphicElement.querySelectorAll('style, foreignObject').forEach(node => node.remove());
            // Typst's default text size is 11pt; match the surrounding document
            // font instead of treating its point dimensions as fixed CSS pixels.
            const width = Number(graphicElement.getAttribute('data-width') || graphicElement.getAttribute('width'));
            if (Number.isFinite(width) && width > 0) graphicElement.style.width = `${width / 11}em`;
            const graphic = graphicElement.outerHTML;
            return `<div class="typst-math-block typst-native">${graphic}</div>`;
        } catch (error) {
            typstInitPromise = null;
            throw error;
        }
    });
    nativeQueue = operation.catch((): void => {});
    return operation;
}

// --- Public API ---

/**
 * Render a Typst math block. Strategy depends on context:
 * - context === "app" → native WASM (high fidelity)
 * - otherwise → transpilation to KaTeX (lightweight)
 *
 * Falls back to transpilation if WASM fails.
 */
export async function renderTypstBlock(
    typstCode: string,
    context: string
): Promise<string> {
    if (context === 'app') {
        try {
            return await renderTypstViaNative(typstCode);
        } catch (err) {
            // Fallback to transpilation if WASM fails to load
            window.webkit?.messageHandlers.logger.postMessage('Typst native fallback: ' + String(err));
        }
    }
    try {
        const html = await renderTypstViaTranspilation(typstCode);
        return `<div class="typst-math-block typst-transpiled">${html}</div>`;
    } catch (err) {
        return `<div class="typst-math-block typst-error">
            <div class="typst-error-title">${rendererLabels().typstRenderError}</div>
            <pre class="typst-error-source">${escapeHtml(typstCode)}</pre>
            <pre class="typst-error-message">${escapeHtml(String(err))}</pre>
        </div>`;
    }
}

function escapeHtml(value: string): string {
    return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
