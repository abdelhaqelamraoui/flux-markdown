import { parseTSV, renderTSVTable } from '../src/tsv';

describe('TSV preview', () => {
  test('preserves literal fields and uneven rows', () => {
    const result = parseTSV('a\tb\n<script>\t\t"x"\nlast\t');
    expect(result.rows).toEqual([['a','b'], ['<script>','','"x"'], ['last','']]);
    expect(result.columns).toBe(3);
  });
  test('does not create a record for a terminating newline', () => {
    expect(parseTSV('a\tb\n').rows).toEqual([['a','b']]);
  });
  test('drops an incomplete final record when byte truncated', () => {
    expect(parseTSV('a\tb\npartial', true).rows).toEqual([['a','b']]);
  });
  test('renders safe semantic table', () => {
    document.body.innerHTML = '';
    const { element } = renderTSVTable('<img src=x>\t=SUM(A1)', false);
    expect(element.querySelectorAll('th')).toHaveLength(2);
    expect(element.querySelector('td')?.textContent).toBe('<img src=x>');
    expect(element.querySelector('img')).toBeNull();
  });
});

test('column truncation is reported without silently narrowing the table', () => {
  expect(parseTSV(Array(101).fill('x').join('\t')).limited).toBe(true);
  const row = Array(100).fill('x').join('\t');
  const result = parseTSV(Array(201).fill(row).join('\n'));
  expect(result.columns).toBe(100);
  expect(result.rows).toHaveLength(200);
  expect(result.limited).toBe(true);
  expect(parseTSV(Array(200).fill(row).join('\n')).limited).toBe(false);
});
test('truncated first record is not called an empty file', () => {
  expect(renderTSVTable('partial', true).element.textContent).not.toContain('Empty TSV file');
});
test('BOM, CR, CRLF, whitespace and interior blank records remain literal', () => {
  expect(parseTSV('\uFEFF a \t\r\n\rZ\n').rows).toEqual([[' a ', ''], [''], ['Z']]);
});
