const mockTypst = { use: jest.fn(), setCompilerInitOptions: jest.fn(), setRendererInitOptions: jest.fn(), svg: jest.fn().mockResolvedValue('<svg/>') };
jest.mock('@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs', () => ({ TypstSnippet: Object.assign(jest.fn().mockImplementation(() => mockTypst), { disableDefaultFontAssets: jest.fn(), preloadFonts: jest.fn() }) }));
import { renderTypstViaNative } from '../src/typst-renderer';
test('native Typst initializes bundled WASM and produces SVG', async () => {
 await expect(renderTypstViaNative('a/b')).resolves.toContain('typst-native');
 expect(mockTypst.setCompilerInitOptions).toHaveBeenCalled();
 expect(mockTypst.setRendererInitOptions).toHaveBeenCalled();
});

test('a failed native compile can be retried', async () => {
 mockTypst.svg.mockRejectedValueOnce(new Error('failed'));
 await expect(renderTypstViaNative('bad')).rejects.toThrow('failed');
 await expect(renderTypstViaNative('a/b')).resolves.toContain('typst-native');
});
