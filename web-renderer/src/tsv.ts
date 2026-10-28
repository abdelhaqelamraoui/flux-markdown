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
    // Bound work even for direct bridge callers; native readers apply the byte limit too.
    let text = input.slice(0, 500 * 1024).replace(/^\uFEFF/, '');
    byteTruncated ||= input.length > 500 * 1024;
    const rows: string[][] = [];
    let columns = 0;
    let limited = false;
    let start = 0;
    for (let i = 0; i <= text.length; i++) {
        const end = i === text.length;
        if (!end && text[i] !== '\r' && text[i] !== '\n') continue;
        if (end && (start === i || byteTruncated)) break;
        if (rows.length === TSV_MAX_ROWS) { limited = true; break; }
        const row: string[] = [];
        let fieldStart = start;
        for (let j = start; j <= i; j++) {
            if (j !== i && text[j] !== '\t') continue;
            if (row.length === TSV_MAX_COLUMNS) { limited = true; break; }
            row.push(text.slice(fieldStart, j));
            fieldStart = j + 1;
        }
        columns = Math.max(columns, row.length);
        rows.push(row);
        if (text[i] === '\r' && text[i + 1] === '\n') i++;
        start = i + 1;
    }
    const count = columns ? Math.min(rows.length, Math.floor(TSV_MAX_CELLS / columns)) : 0;
    if (count < rows.length) limited = true;
    return { rows: rows.slice(0, count), columns, truncated: byteTruncated, empty: rows.length === 0, limited };
}

export function renderTSVTable(input: string, byteTruncated = false): { element: HTMLElement; result: TSVPreviewResult } {
    const result = parseTSV(input, byteTruncated);
    const wrapper = document.createElement('div');
    wrapper.className = 'tsv-preview';
    if (result.empty) {
        const empty = document.createElement('p');
        empty.className = 'tsv-empty';
        empty.textContent = result.truncated ? rendererLabels().tsvRecordTooLarge : rendererLabels().tsvEmpty;
        wrapper.appendChild(empty);
        return { element: wrapper, result };
    }
    const scroll = document.createElement('div');
    scroll.className = 'tsv-scroll';
    scroll.tabIndex = 0;
    scroll.setAttribute('role', 'region');
    scroll.setAttribute('aria-label', 'TSV');
    const table = document.createElement('table');
    table.className = 'tsv-table';
    const head = document.createElement('thead');
    const header = document.createElement('tr');
    for (let i = 0; i < result.columns; i++) {
        const cell = document.createElement('th');
        cell.scope = 'col';
        cell.textContent = `${rendererLabels().tsvColumn} ${i + 1}`;
        header.appendChild(cell);
    }
    head.appendChild(header);
    table.appendChild(head);
    const body = document.createElement('tbody');
    for (const [index, row] of result.rows.entries()) {
        const tr = document.createElement('tr');
        tr.dataset.sourceLine = String(index + 1);
        tr.dataset.sourceLineEnd = String(index + 1);
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
        notice.textContent = `${rendererLabels().tsvPreviewLimited} (${result.rows.length} × ${result.columns}; 500 KiB / 1,000 × 100 / 20,000)`;
        wrapper.appendChild(notice);
    }
    return { element: wrapper, result };
}
import { rendererLabels } from './renderer-strings';

