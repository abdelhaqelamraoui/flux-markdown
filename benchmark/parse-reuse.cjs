// Narrow parse/outline microbenchmark; does not claim end-to-end startup gains.
const { performance } = require('node:perf_hooks');
const MarkdownIt = require('../web-renderer/node_modules/markdown-it');
const fs = require('node:fs');
const md = new MarkdownIt({html: true, linkify: true, typographer: true});
const text = fs.readFileSync('benchmark/fixtures/04-large-prose.md', 'utf8');
function doubleParse() { md.parse(text, {}); return md.render(text, {}); }
function singleParse() { const env = {}; const tokens = md.parse(text, env); return md.renderer.render(tokens, md.options, env); }
if (doubleParse() !== singleParse()) throw new Error('rendered HTML differs');
for (let i=0;i<5;i++) { doubleParse(); singleParse(); }
const samples = { doubleParse: [], singleParse: [] };
for (let i=0;i<30;i++) {
 for (const [name, fn] of Object.entries({doubleParse, singleParse})) {
  const start=performance.now();fn();samples[name].push(performance.now()-start);
 }
}
console.log(JSON.stringify({date:new Date().toISOString(), node:process.version, arch:process.arch, fixtureBytes:Buffer.byteLength(text), samples, medianMs:Object.fromEntries(Object.entries(samples).map(([k,v])=>[k,v.sort((a,b)=>a-b)[15]]))},null,2));
