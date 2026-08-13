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

ok('whale rendered in hero', els.heroWhale.innerHTML.includes('<svg') && els.heroWhale.innerHTML.includes('#4d6bfe'));
ok('stats rendered', els.stats.innerHTML.includes('plugins') && els.stats.innerHTML.includes('分类'));
ok('chips rendered (10 cats + all)', els.chips.innerHTML.split('class="chip').length - 1 === 11);
ok('list rendered rows (316)', rowCount() === 316);
ok('tag cloud rendered', (els.kwcloud.innerHTML.match(/class="kwt/g) || []).length >= 15);
ok('row kw chips shown', els.list.innerHTML.includes('class="kw"'));
ok('board hidden by default', els.board.hidden === true);

// keyword filter via tag cloud click
const kwEl = { getAttribute: () => '记忆', _listeners: {} };
els.kwcloud._listeners.click({ target: { closest: () => kwEl } });
const rowsKw = rowCount();
ok('keyword filter (记忆) narrows list', rowsKw > 0 && rowsKw < 316);
els.kwcloud._listeners.click({ target: { closest: () => ({ getAttribute: () => '' }) } });
ok('keyword cleared restores rows', rowCount() === 316);

// search
els.q.value = 'memory';
els.q._listeners.input({ target: { value: 'memory' } });
ok('search narrows list (memory)', rowCount() > 0 && rowCount() < 316);
els.q._listeners.input({ target: { value: '' } });

// category filter
const chipFun = { getAttribute: () => '游戏与整活', _listeners: {} };
els.chips._listeners.click({ target: { closest: () => chipFun } });
ok('category filter (游戏与整活 = 20)', rowCount() === 20);
els.chips._listeners.click({ target: { closest: () => ({ getAttribute: () => '__all__' }) } });

// leaderboard view
const viewBoard = { getAttribute: () => 'board', classList: { toggle() {} }, _listeners: {} };
viewsEl._listeners.click({ target: { closest: () => viewBoard } });
ok('board view shows top 50', (els.board.innerHTML.match(/class="brow"/g) || []).length === 50);
ok('board has rank medals', els.board.innerHTML.includes('🥇') && els.board.innerHTML.includes('⭐'));

// sort Stars asc
const sortAsc = { getAttribute: () => 'starsAsc', classList: { toggle() {} }, _listeners: {} };
sortEl._listeners.click({ target: { closest: () => sortAsc } });
ok('sort starsAsc still renders rows', rowCount() === 316);
console.log('done');
