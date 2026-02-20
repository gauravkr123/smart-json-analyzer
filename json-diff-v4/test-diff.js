#!/usr/bin/env node
/**
 * Test script for JSON deep-diff logic (same algo as index.html).
 * Run: node test-diff.js
 */

function normalizeForKeyCompare(val, opts) {
  if (val === null) return 'null';
  if (typeof val === 'boolean') return String(val);
  if (typeof val === 'number') return String(val);
  if (typeof val === 'string') return opts.ignoreCase ? val.toLowerCase() : val;
  if (Array.isArray(val)) {
    const mapped = val.map(v => normalizeForKeyCompare(v, opts));
    return JSON.stringify(opts.ignoreOrder ? [...mapped].sort() : mapped);
  }
  if (typeof val === 'object') {
    const keys = Object.keys(val).sort();
    const o = {};
    for (const k of keys) {
      if (opts.ignoreKeys.includes(k)) continue;
      o[k] = normalizeForKeyCompare(val[k], opts);
    }
    return JSON.stringify(o);
  }
  return String(val);
}

function flattenLeaves(val, basePath) {
  if (val === null || typeof val !== 'object') return [{ path: basePath, value: val }];
  if (Array.isArray(val)) {
    const out = [];
    val.forEach((v, i) => out.push(...flattenLeaves(v, basePath + '[' + i + ']')));
    return out.length ? out : [{ path: basePath, value: [] }];
  }
  const out = [];
  for (const k of Object.keys(val)) {
    const p = basePath ? basePath + '.' + k : k;
    out.push(...flattenLeaves(val[k], p));
  }
  return out.length ? out : [{ path: basePath, value: {} }];
}

function compareValues(a, b, path, opts, out) {
  const skip = (key) => key && opts.ignoreKeys.includes(key);
  const lastKey = path.replace(/\[\d+\]/g, '').split('.').filter(Boolean).pop();
  if (lastKey && skip(lastKey)) return;

  if (typeof a !== typeof b) {
    out.push({ type: 'changed', path, left: a, right: b });
    return;
  }
  if (a === null && b === null) return;
  if (a === null || b === null) {
    out.push({ type: 'changed', path, left: a, right: b });
    return;
  }
  if (typeof a !== 'object') {
    const va = typeof a === 'string' && opts.ignoreCase ? a.toLowerCase() : a;
    const vb = typeof b === 'string' && opts.ignoreCase ? b.toLowerCase() : b;
    if (va !== vb) out.push({ type: 'changed', path, left: a, right: b });
    return;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    if (opts.ignoreOrder) {
      /* O(n+m) hash-based matching */
      const mapB = new Map();
      for (let j = 0; j < b.length; j++) {
        const h = normalizeForKeyCompare(b[j], opts);
        if (!mapB.has(h)) mapB.set(h, []);
        mapB.get(h).push(j);
      }
      const usedB = new Set(), unmatchedA = [];
      for (let i = 0; i < a.length; i++) {
        const h = normalizeForKeyCompare(a[i], opts);
        const slots = mapB.get(h);
        if (slots && slots.length) { usedB.add(slots.shift()); }
        else { unmatchedA.push(i); }
      }
      const unmatchedB = [];
      for (let j = 0; j < b.length; j++) { if (!usedB.has(j)) unmatchedB.push(j); }
      if (unmatchedA.length || unmatchedB.length) {
        const pairLen = Math.min(unmatchedA.length, unmatchedB.length);
        for (let x = 0; x < pairLen; x++) {
          compareValues(a[unmatchedA[x]], b[unmatchedB[x]], path + '[' + unmatchedA[x] + ']', opts, out);
        }
        for (let x = pairLen; x < unmatchedA.length; x++) {
          flattenLeaves(a[unmatchedA[x]], path + '[' + unmatchedA[x] + ']').forEach(l => out.push({ type: 'removed', path: l.path, value: l.value }));
        }
        for (let x = pairLen; x < unmatchedB.length; x++) {
          flattenLeaves(b[unmatchedB[x]], path + '[' + unmatchedB[x] + ']').forEach(l => out.push({ type: 'added', path: l.path, value: l.value }));
        }
      }
      return;
    }
    const len = Math.max(a.length, b.length);
    for (let i = 0; i < len; i++) {
      const p = path + '[' + i + ']';
      if (i >= a.length) {
        flattenLeaves(b[i], p).forEach(l => out.push({ type: 'added', path: l.path, value: l.value }));
      } else if (i >= b.length) {
        flattenLeaves(a[i], p).forEach(l => out.push({ type: 'removed', path: l.path, value: l.value }));
      } else {
        compareValues(a[i], b[i], p, opts, out);
      }
    }
    return;
  }
  if (Array.isArray(a) !== Array.isArray(b)) {
    out.push({ type: 'changed', path, left: a, right: b });
    return;
  }
  const prefix = path ? path + '.' : '';
  const allKeys = new Set([...Object.keys(a), ...Object.keys(b)]);
  for (const k of allKeys) {
    if (skip(k)) continue;
    const p = prefix + k;
    if (!(k in a)) {
      flattenLeaves(b[k], p).forEach(l => out.push({ type: 'added', path: l.path, value: l.value }));
    } else if (!(k in b)) {
      flattenLeaves(a[k], p).forEach(l => out.push({ type: 'removed', path: l.path, value: l.value }));
    } else {
      compareValues(a[k], b[k], p, opts, out);
    }
  }
}

function runDiff(a, b, opts = {}) {
  const safeOpts = {
    ignoreOrder: !!opts.ignoreOrder,
    ignoreCase: !!opts.ignoreCase,
    ignoreKeys: Array.isArray(opts.ignoreKeys) ? opts.ignoreKeys : [],
  };
  const out = [];
  compareValues(a, b, '', safeOpts, out);
  return out;
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

let passed = 0;
let failed = 0;

function test(name, a, b, opts, expectCountOrPredicate) {
  try {
    const diffs = runDiff(a, b, opts);
    if (typeof expectCountOrPredicate === 'number') {
      assert(diffs.length === expectCountOrPredicate, `expected ${expectCountOrPredicate} diffs, got ${diffs.length}: ${JSON.stringify(diffs)}`);
    } else {
      assert(expectCountOrPredicate(diffs), `predicate failed. diffs: ${JSON.stringify(diffs)}`);
    }
    console.log('  ✓ ' + name);
    passed++;
  } catch (e) {
    console.log('  ✗ ' + name + ' — ' + e.message);
    failed++;
  }
}

console.log('JSON Deep Diff — logic tests\n');

// Basic: same object → no diffs
test('Same object → 0 diffs', { x: 1 }, { x: 1 }, {}, 0);
test('Same nested → 0 diffs', { a: { b: 2 } }, { a: { b: 2 } }, {}, 0);
test('Same array → 0 diffs', [1, 2, 3], [1, 2, 3], {}, 0);

// Added/removed/changed
test('Added key → 1 added', { a: 1 }, { a: 1, b: 2 }, {}, (d) => d.length === 1 && d[0].type === 'added' && d[0].path === 'b');
test('Removed key → 1 removed', { a: 1, b: 2 }, { a: 1 }, {}, (d) => d.length === 1 && d[0].type === 'removed' && d[0].path === 'b');
test('Changed value → 1 changed', { a: 1 }, { a: 2 }, {}, (d) => d.length === 1 && d[0].type === 'changed' && d[0].path === 'a');
test('Array longer in B → added at index', [1, 2], [1, 2, 3], {}, (d) => d.length === 1 && d[0].type === 'added' && d[0].path === '[2]' && d[0].value === 3);
test('Array shorter in B → removed at index', [1, 2, 3], [1, 2], {}, (d) => d.length === 1 && d[0].type === 'removed' && d[0].path === '[2]' && d[0].value === 3);

// Ignore case
test('Ignore case: same content different case → 0 diffs', { s: 'Hello' }, { s: 'hello' }, { ignoreCase: true }, 0);
test('Ignore case: off → 1 changed', { s: 'Hello' }, { s: 'hello' }, { ignoreCase: false }, (d) => d.length === 1 && d[0].type === 'changed');

// Ignore order (arrays)
test('Ignore order: same elements different order → 0 diffs', [1, 2, 3], [3, 2, 1], { ignoreOrder: true }, 0);
test('Ignore order: extra in B → 1 added', [1, 2], [1, 2, 3], { ignoreOrder: true }, (d) => d.length === 1 && d[0].type === 'added');
test('Ignore order: missing in B → 1 removed', [1, 2, 3], [1, 2], { ignoreOrder: true }, (d) => d.length === 1 && d[0].type === 'removed');

// Ignore keys
test('Ignore keys: differing id only → 0 diffs', { id: 1, name: 'x' }, { id: 2, name: 'x' }, { ignoreKeys: ['id'] }, 0);
test('Ignore keys: name differs → 1 changed', { id: 1, name: 'a' }, { id: 2, name: 'b' }, { ignoreKeys: ['id'] }, (d) => d.length === 1 && d[0].path === 'name');
test('Ignore keys: nested', { user: { id: 1, role: 'admin' } }, { user: { id: 2, role: 'user' } }, { ignoreKeys: ['id'] }, (d) => d.length === 1 && d[0].path === 'user.role' && d[0].type === 'changed');

// Combined
test('Ignore order + case: arrays and string', [{ s: 'Abc' }], [{ s: 'abc' }], { ignoreOrder: true, ignoreCase: true }, 0);
test('Ignore keys + nested path', { meta: { ts: 1 }, data: { x: 1 } }, { meta: { ts: 2 }, data: { x: 1 } }, { ignoreKeys: ['ts'] }, 0);

// Sample JSONs (real-world style)
const sampleA = { name: 'Alice', age: 30, tags: ['a', 'b'], meta: { id: 101, created: '2024-01-01' } };
const sampleB = { name: 'Alice', age: 31, tags: ['b', 'a'], meta: { id: 102, created: '2024-01-01' } };
test('Sample: ignore id + order → only age diff', sampleA, sampleB, { ignoreKeys: ['id'], ignoreOrder: true }, (d) => d.length === 1 && d[0].path === 'age');
test('Sample: ignore id only → age + tag order diffs (3)', sampleA, sampleB, { ignoreKeys: ['id'] }, (d) => d.length === 3);

// Flattening: added/removed objects show individual keys, not whole object
test('Added object → flattened to leaf keys', { a: 1 }, { a: 1, b: { x: 1, y: 2 } }, {},
  (d) => d.length === 2 && d.every(e => e.type === 'added') && d[0].path === 'b.x' && d[1].path === 'b.y');
test('Removed object → flattened to leaf keys', { a: 1, b: { x: 1, y: 2 } }, { a: 1 }, {},
  (d) => d.length === 2 && d.every(e => e.type === 'removed') && d[0].path === 'b.x' && d[1].path === 'b.y');
test('Array extra object → flattened', [{ name: 'a' }], [{ name: 'a' }, { name: 'b', age: 5 }], {},
  (d) => d.length === 2 && d.every(e => e.type === 'added') && d[0].path === '[1].name' && d[1].path === '[1].age');
test('Ignore order: unmatched objects → paired + recurse into keys', [{ id: 1, v: 'old' }], [{ id: 1, v: 'new' }], { ignoreOrder: true },
  (d) => d.length === 1 && d[0].type === 'changed' && d[0].path.includes('v'));

console.log('\n' + passed + ' passed, ' + failed + ' failed');
process.exit(failed > 0 ? 1 : 0);
