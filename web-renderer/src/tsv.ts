export interface TSVPreviewResult {
    rows: string[][];
    columns: number;
    truncated: boolean;
    empty: boolean;
    limited: boolean;
}

export const TSV_MAX_ROWS = 1000;
export const TSV_MAX_COLUMNS = 100;
export const TSV_MAX_CELLS = 20000;

/** Parse the deliberately literal TSV dialect used by the QuickLook preview. */
export function parseTSV(input: string, byteTruncated = false): TSVPreviewResult {
    const text = input.replace(/^\uFEFF/, '');
    if (text.length === 0) return { rows: [], columns: 0, truncated: byteTruncated, empty: true, limited: false };
    const raw = text.split(/\r\n|\n|\r/);
    const hasTerminatingNewline = /(?:\r\n|\n|\r)$/.test(text);
    if (byteTruncated && !hasTerminatingNewline) raw.pop();
    if (hasTerminatingNewline && raw[raw.length - 1] === '') raw.pop();
    if (raw.length === 0) return { rows: [], columns: 0, truncated: byteTruncated, empty: true, limited: false };
    const rows: string[][] = [];
    let columns = 0;
    let limited = false;
    for (const line of raw) {
        if (rows.length >= TSV_MAX_ROWS) { limited = true; break; }
        const cells = line.split('\t');
        columns = Math.max(columns, Math.min(cells.length, TSV_MAX_COLUMNS));
        rows.push(cells.slice(0, TSV_MAX_COLUMNS));
        if (rows.length * columns >= TSV_MAX_CELLS) { limited = true; break; }
    }
    const maxColumns = Math.min(columns, Math.max(1, Math.floor(TSV_MAX_CELLS / Math.max(1, rows.length))));
    const finalColumns = Math.min(columns, TSV_MAX_COLUMNS, maxColumns);
    return { rows: rows.map(row => row.slice(0, finalColumns)), columns: finalColumns, truncated: byteTruncated, empty: false, limited };
}

export function renderTSVTable(input: string, byteTruncated = false): { element: HTMLElement; result: TSVPreviewResult } {
    const result = parseTSV(input, byteTruncated);
    const wrapper = document.createElement('div');
    wrapper.className = 'tsv-preview';
    if (result.empty) {
        const empty = document.createElement('p');
        empty.className = 'tsv-empty';
        empty.textContent = rendererLabels().tsvEmpty;
        wrapper.appendChild(empty);
        return { element: wrapper, result };
    }
    const scroll = document.createElement('div');
    scroll.className = 'tsv-scroll';
    scroll.tabIndex = 0;
    const table = document.createElement('table');
    table.className = 'tsv-table';
    const head = document.createElement('thead');
    const header = document.createElement('tr');
    for (let i = 0; i < result.columns; i++) {
        const cell = document.createElement('th');
        cell.scope = 'col';
        cell.textContent = `Column ${i + 1}`;
        header.appendChild(cell);
    }
    head.appendChild(header);
    table.appendChild(head);
    const body = document.createElement('tbody');
    for (const row of result.rows) {
        const tr = document.createElement('tr');
        for (let i = 0; i < result.columns; i++) {
            const td = document.createElement('td');
            td.textContent = row[i] ?? '';
            tr.appendChild(td);
        }
        body.appendChild(tr);
    }
    table.appendChild(body);
    scroll.appendChild(table);
    wrapper.appendChild(scroll);
    if (result.truncated || result.limited) {
        const notice = document.createElement('p');
        notice.className = 'tsv-truncated';
        notice.textContent = rendererLabels().tsvPreviewLimited;
        wrapper.appendChild(notice);
    }
    return { element: wrapper, result };
}
import { rendererLabels } from './renderer-strings';

