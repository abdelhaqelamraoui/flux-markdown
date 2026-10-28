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
