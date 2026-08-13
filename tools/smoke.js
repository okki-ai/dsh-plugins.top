// Smoke-test the built site (repo root index.html) with a minimal DOM shim.
// Path-independent: expects to run from tools/ with index.html at repo root.
const fs = require('fs');
const path = require('path');
const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
const m = html.match(/<script>([\s\S]*?)<\/script>/g);
if (!m || m.length < 2) { console.error('FAIL: script blocks missing'); process.exit(1); }
const dataBlock = m[0].replace(/<\/?script>/g, '');
const logicBlock = m[1].replace(/<\/?script>/g, '');

function makeEl() {
  return {
    innerHTML: '', hidden: false, value: '', style: {},
    _listeners: {},
    addEventListener(type, fn) { this._listeners[type] = fn; },
    getAttribute() { return ''; },
    classList: { toggle() {}, contains() { return false; } },
    querySelectorAll() { return []; },
  };
}
const els = {};
['miniWhale', 'heroWhale', 'stats', 'chips', 'q', 'list', 'empty', 'kwcloud', 'board', 'thead', 'searchWrap'].forEach(id => els[id] = makeEl());
const sortEl = makeEl(), viewsEl = makeEl(), kwbarEl = makeEl(), controlsEl = makeEl();
global.window = { AWESOME: null };
global.document = {
  getElementById(id) { return els[id] || null; },
  querySelector(sel) {
    if (sel === '.sort') return sortEl;
    if (sel === '.views') return viewsEl;
    if (sel === '.kwbar') return kwbarEl;
    if (sel === '.controls') return controlsEl;
    return null;
  },
  querySelectorAll() { return []; },
};
global.fetch = () => Promise.reject(new Error('offline'));
global.encodeURIComponent = encodeURIComponent;

eval(dataBlock + '\n' + 'global.__dataOK = window.AWESOME && window.AWESOME.cats;');
if (!global.__dataOK) { console.error('FAIL: data did not load'); process.exit(1); }
eval(logicBlock);

const ok = (name, cond) => { console.log((cond ? 'PASS' : 'FAIL') + ' - ' + name); if (!cond) process.exitCode = 1; };
const rowCount = () => (els.list.innerHTML.match(/class="row"/g) || []).length;

// data-driven expectations (CI discovers new plugins daily, so counts must not be hardcoded)
const catsAll = Object.keys(window.AWESOME.cats);
const expectedTotal = catsAll.reduce((n, cn) => n + window.AWESOME.cats[cn].length, 0);
const expectedChips = catsAll.length + 1;

ok('whale rendered in hero', els.heroWhale.innerHTML.includes('<svg') && els.heroWhale.innerHTML.includes('#4d6bfe'));
ok('stats rendered', els.stats.innerHTML.includes('plugins') && els.stats.innerHTML.includes('分类'));
ok('chips rendered (all cats + all)', els.chips.innerHTML.split('class="chip').length - 1 === expectedChips);
ok('list rendered all rows (' + expectedTotal + ')', rowCount() === expectedTotal);
ok('tag cloud rendered', (els.kwcloud.innerHTML.match(/class="kwt/g) || []).length >= 15);
ok('row kw chips shown', els.list.innerHTML.includes('class="kw"'));
ok('board hidden by default', els.board.hidden === true);

// keyword filter via tag cloud click
const kwEl = { getAttribute: () => '记忆', _listeners: {} };
els.kwcloud._listeners.click({ target: { closest: () => kwEl } });
const rowsKw = rowCount();
ok('keyword filter (记忆) narrows list', rowsKw > 0 && rowsKw < expectedTotal);
els.kwcloud._listeners.click({ target: { closest: () => ({ getAttribute: () => '' }) } });
ok('keyword cleared restores rows', rowCount() === expectedTotal);

// search
els.q.value = 'memory';
els.q._listeners.input({ target: { value: 'memory' } });
ok('search narrows list (memory)', rowCount() > 0 && rowCount() < expectedTotal);
els.q._listeners.input({ target: { value: '' } });

// category filter (data-driven)
const catName = '游戏与整活';
const catExpect = window.AWESOME.cats[catName] ? window.AWESOME.cats[catName].length : 0;
const chipFun = { getAttribute: () => catName, _listeners: {} };
els.chips._listeners.click({ target: { closest: () => chipFun } });
ok('category filter (' + catName + ' = ' + catExpect + ')', rowCount() === catExpect);
els.chips._listeners.click({ target: { closest: () => ({ getAttribute: () => '__all__' }) } });

// leaderboard view
const viewBoard = { getAttribute: () => 'board', classList: { toggle() {} }, _listeners: {} };
viewsEl._listeners.click({ target: { closest: () => viewBoard } });
const boardExpect = Math.min(50, expectedTotal);
ok('board view shows top ' + boardExpect, (els.board.innerHTML.match(/class="brow"/g) || []).length === boardExpect);
ok('board has rank medals', els.board.innerHTML.includes('🥇') && els.board.innerHTML.includes('⭐'));

// sort Stars asc
const sortAsc = { getAttribute: () => 'starsAsc', classList: { toggle() {} }, _listeners: {} };
sortEl._listeners.click({ target: { closest: () => sortAsc } });
ok('sort starsAsc still renders rows', rowCount() === expectedTotal);
console.log('done');
