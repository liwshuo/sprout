// tests/helpers/fake-cloud.js —— 轻量内存版 CloudBase 数据库
// 仅实现 childShare 云函数用到的查询面，用于在 Node 下驱动云函数鉴权/事务逻辑：
//   collection(name).where(cond).orderBy(f,dir).skip(n).limit(n).get()
//   collection(name).where(cond).update({data})   // 批量更新
//   collection(name).add({data})
//   collection(name).doc(id).get() / update({data}) / set({data}) / remove()
//   command: _.neq / _.eq / _.in
//   runTransaction(fn)  // 回调抛错则整体 reject（与 wx-server-sdk 行为一致）
//
// 说明：真实 CloudBase 语义远比这里复杂，本 fake 只保证被测分支的行为等价。

function clone(obj) {
  return obj == null ? obj : JSON.parse(JSON.stringify(obj));
}

// —— command（查询条件运算符）——
const command = {
  neq: (v) => ({ __op: 'neq', v }),
  eq: (v) => ({ __op: 'eq', v }),
  in: (arr) => ({ __op: 'in', arr }),
};

function matchCond(doc, cond) {
  return Object.keys(cond).every((key) => {
    const expect = cond[key];
    const actual = doc[key];
    if (expect && typeof expect === 'object' && expect.__op) {
      if (expect.__op === 'neq') return actual !== expect.v;
      if (expect.__op === 'eq') return actual === expect.v;
      if (expect.__op === 'in') return expect.arr.indexOf(actual) !== -1;
      return false;
    }
    return actual === expect;
  });
}

class Query {
  constructor(store, cond) {
    this.store = store; // 数组引用（同一集合的真实文档）
    this.cond = cond || {};
    this._order = null;
    this._skip = 0;
    this._limit = Infinity;
  }

  where(cond) {
    return new Query(this.store, Object.assign({}, this.cond, cond))
      ._carry(this);
  }

  _carry(prev) {
    this._order = prev._order;
    this._skip = prev._skip;
    this._limit = prev._limit;
    return this;
  }

  orderBy(field, dir) {
    this._order = [field, dir || 'asc'];
    return this;
  }

  skip(n) { this._skip = n; return this; }
  limit(n) { this._limit = n; return this; }

  _filtered() {
    let rows = this.store.filter((doc) => matchCond(doc, this.cond));
    if (this._order) {
      const [f, dir] = this._order;
      const factor = dir === 'desc' ? -1 : 1;
      rows = rows.slice().sort((a, b) => {
        if (a[f] === b[f]) return 0;
        return (a[f] < b[f] ? -1 : 1) * factor;
      });
    }
    return rows;
  }

  async get() {
    const rows = this._filtered().slice(this._skip, this._skip + this._limit);
    return { data: rows.map(clone) };
  }

  async update({ data }) {
    const rows = this._filtered();
    rows.forEach((doc) => Object.assign(doc, clone(data)));
    return { stats: { updated: rows.length } };
  }

  async remove() {
    const rows = this._filtered();
    rows.forEach((doc) => { doc.isDeleted = true; });
    return { stats: { removed: rows.length } };
  }
}

class DocRef {
  constructor(store, id) {
    this.store = store;
    this.id = id;
  }

  _find() {
    return this.store.find((d) => d._id === this.id);
  }

  async get() {
    const doc = this._find();
    if (!doc) {
      const err = new Error('document does not exist');
      err.errCode = -1;
      throw err;
    }
    return { data: clone(doc) };
  }

  async update({ data }) {
    const doc = this._find();
    if (!doc) throw new Error('document does not exist');
    Object.assign(doc, clone(data));
    return { stats: { updated: 1 } };
  }

  async set({ data }) {
    let doc = this._find();
    if (!doc) {
      doc = { _id: this.id };
      this.store.push(doc);
    }
    Object.assign(doc, clone(data));
    return { _id: this.id };
  }

  async remove() {
    const idx = this.store.findIndex((d) => d._id === this.id);
    if (idx >= 0) this.store.splice(idx, 1);
    return { stats: { removed: idx >= 0 ? 1 : 0 } };
  }
}

class CollRef {
  constructor(db, name) {
    this.db = db;
    this.name = name;
  }

  get store() {
    if (!this.db.data[this.name]) this.db.data[this.name] = [];
    return this.db.data[this.name];
  }

  where(cond) { return new Query(this.store, cond); }
  orderBy(f, dir) { return new Query(this.store, {}).orderBy(f, dir); }
  skip(n) { return new Query(this.store, {}).skip(n); }
  limit(n) { return new Query(this.store, {}).limit(n); }
  async get() { return new Query(this.store, {}).get(); }

  doc(id) { return new DocRef(this.store, id); }

  async add({ data }) {
    const doc = clone(data);
    if (!doc._id) doc._id = `auto_${this.name}_${this.store.length + 1}_${Math.random().toString(16).slice(2, 8)}`;
    this.store.push(doc);
    return { _id: doc._id };
  }
}

class FakeDB {
  constructor(seed) {
    this.data = {};
    this.command = command;
    if (seed) {
      Object.keys(seed).forEach((name) => {
        this.data[name] = clone(seed[name]);
      });
    }
  }

  collection(name) { return new CollRef(this, name); }

  async runTransaction(fn) {
    // 简化：不做真正回滚（被测逻辑抛错即中止，等价于失败），回调抛错则向上抛出
    const transaction = { collection: (name) => new CollRef(this, name) };
    return await fn(transaction);
  }
}

/**
 * 生成 wx-server-sdk 的 mock 工厂。
 * @param {object} ctx  getWXContext 返回值 { OPENID, UNIONID }
 * @param {object} seed 初始集合数据 { collectionName: [docs...] }
 * @returns {{ sdk: object, db: FakeDB }}
 */
function makeServerSdk(ctx, seed) {
  const db = new FakeDB(seed);
  const sdk = {
    DYNAMIC_CURRENT_ENV: 'test-env',
    init() {},
    database() { return db; },
    getWXContext() { return Object.assign({ OPENID: '', UNIONID: '' }, ctx); },
    // wxacode 等其余能力本套用例用不到，留空桩
    openapi: {},
  };
  return { sdk, db };
}

module.exports = { FakeDB, command, makeServerSdk };
