// tests/cloudfunctions/childShare.test.js —— childShare 云函数鉴权/事务逻辑单测
// 用内存版 CloudBase（tests/helpers/fake-cloud）驱动，覆盖：
//   listChildData：集合白名单 / 成员鉴权 / 分页 / childId 过滤
//   listTodos：成员鉴权
//   deleteChild：仅创建者可删 + 软删关联业务数据
//   convertTodoToRecord：未完成拦截 / 幂等去重 / 生成确定性记录

const { FakeDB } = require('../helpers/fake-cloud');

// —— 稳定 facade：childShare 在模块加载时捕获 database() 与 command，
//    通过 facade 委派到可替换的 mockDb，从而支持每个用例独立 seed。
//    注意：jest.mock 工厂会被提升到文件顶部，只能引用以 `mock` 开头的外部变量，
//    因此这里的可变持有量统一用 mock 前缀命名。 —— //
let mockDb = new FakeDB();
let mockCtx = { OPENID: '', UNIONID: '' };

jest.mock('wx-server-sdk', () => {
  // eslint-disable-next-line global-require
  const { command } = require('../helpers/fake-cloud');
  return {
    DYNAMIC_CURRENT_ENV: 'test-env',
    init() {},
    database: () => ({
      command,
      collection: (name) => mockDb.collection(name),
      runTransaction: (fn) => mockDb.runTransaction(fn),
    }),
    getWXContext: () => mockCtx,
  };
}, { virtual: true });

// 必须在 mock 之后再 require 被测模块
const childShare = require('../../cloudfunctions/childShare/index.js');

function setup(seed, ctx) {
  mockDb = new FakeDB(seed);
  mockCtx = Object.assign({ OPENID: '', UNIONID: '' }, ctx);
}

// 便捷构造：孩子 c1 + 家长 p1(创建者) 的成员关系
function withOwnerMembership(extra = {}) {
  return Object.assign({
    child_members: [
      { _id: 'm1', childId: 'c1', ownerId: 'p1', openid: 'p1', isOwner: true, isDeleted: false },
    ],
    children: [
      { _id: 'ch1', uuid: 'c1', ownerId: 'p1', name: '小明', members: ['p1'], isDeleted: false },
    ],
  }, extra);
}

describe('childShare 未登录守卫', () => {
  test('无 openid/unionid 时任何 action 都被拒', async () => {
    setup({}, {});
    const res = await childShare.main({ action: 'listChildData', collection: 'daily_records', childId: 'c1' });
    expect(res).toEqual({ ok: false, error: '未登录，无法操作' });
  });
});

describe('childShare.listChildData', () => {
  test('非白名单集合被拒', async () => {
    setup(withOwnerMembership(), { OPENID: 'p1' });
    const res = await childShare.main({ action: 'listChildData', collection: 'users', childId: 'c1' });
    expect(res).toEqual({ ok: false, error: '不支持的集合' });
  });

  test('非成员被拒', async () => {
    setup(withOwnerMembership(), { OPENID: 'stranger' });
    const res = await childShare.main({ action: 'listChildData', collection: 'daily_records', childId: 'c1' });
    expect(res.ok).toBe(false);
    expect(res.error).toMatch(/无权/);
  });

  test('成员可读且只返回该 childId 的未删除数据', async () => {
    setup(withOwnerMembership({
      daily_records: [
        { _id: 'd1', uuid: 'd1', childId: 'c1', isDeleted: false },
        { _id: 'd2', uuid: 'd2', childId: 'c1', isDeleted: true },   // 已删除 → 排除
        { _id: 'd3', uuid: 'd3', childId: 'c2', isDeleted: false },  // 别的孩子 → 排除
      ],
    }), { OPENID: 'p1' });
    const res = await childShare.main({ action: 'listChildData', collection: 'daily_records', childId: 'c1' });
    expect(res.ok).toBe(true);
    expect(res.items.map((x) => x.uuid)).toEqual(['d1']);
  });

  test('超过单页 100 条时分页拉全', async () => {
    const many = [];
    for (let i = 0; i < 150; i++) {
      many.push({ _id: `d${String(i).padStart(3, '0')}`, uuid: `d${i}`, childId: 'c1', isDeleted: false });
    }
    setup(withOwnerMembership({ daily_records: many }), { OPENID: 'p1' });
    const res = await childShare.main({ action: 'listChildData', collection: 'daily_records', childId: 'c1' });
    expect(res.ok).toBe(true);
    expect(res.items).toHaveLength(150);
  });

  test('course_templates 属于白名单，成员可读该孩子的课程模板', async () => {
    setup(withOwnerMembership({
      course_templates: [
        { _id: 't1', uuid: 't1', childId: 'c1', isDeleted: false, name: '数学', type: 'school' },
        { _id: 't2', uuid: 't2', childId: 'c1', isDeleted: true },   // 已删除 → 排除
        { _id: 't3', uuid: 't3', childId: 'c2', isDeleted: false },  // 别的孩子 → 排除
      ],
    }), { OPENID: 'p1' });
    const res = await childShare.main({ action: 'listChildData', collection: 'course_templates', childId: 'c1' });
    expect(res.ok).toBe(true);
    expect(res.items.map((x) => x.uuid)).toEqual(['t1']);
  });
});

describe('childShare.listTodos', () => {
  test('非成员被拒', async () => {
    setup(withOwnerMembership(), { OPENID: 'stranger' });
    const res = await childShare.main({ action: 'listTodos', childId: 'c1' });
    expect(res.ok).toBe(false);
    expect(res.error).toMatch(/无权/);
  });

  test('成员返回待办列表', async () => {
    setup(withOwnerMembership({
      todos: [
        { _id: 't1', uuid: 't1', childId: 'c1', title: 'A', isDeleted: false },
        { _id: 't2', uuid: 't2', childId: 'c1', title: 'B', isDeleted: false },
      ],
    }), { OPENID: 'p1' });
    const res = await childShare.main({ action: 'listTodos', childId: 'c1' });
    expect(res.ok).toBe(true);
    expect(res.todos.map((t) => t.uuid).sort()).toEqual(['t1', 't2']);
  });
});

describe('childShare.deleteChild', () => {
  test('非创建者不能删除', async () => {
    setup(withOwnerMembership({
      child_members: [
        { _id: 'm1', childId: 'c1', ownerId: 'p1', openid: 'p1', isOwner: true, isDeleted: false },
        { _id: 'm2', childId: 'c1', ownerId: 'p2', openid: 'p2', isOwner: false, isDeleted: false },
      ],
    }), { OPENID: 'p2' });
    const res = await childShare.main({ action: 'deleteChild', childId: 'c1' });
    expect(res.ok).toBe(false);
    expect(res.error).toMatch(/创建者/);
  });

  test('创建者删除时软删档案与关联业务数据', async () => {
    setup(withOwnerMembership({
      daily_records: [{ _id: 'd1', uuid: 'd1', childId: 'c1', isDeleted: false }],
      todos: [{ _id: 't1', uuid: 't1', childId: 'c1', isDeleted: false }],
    }), { OPENID: 'p1' });

    const res = await childShare.main({ action: 'deleteChild', childId: 'c1' });
    expect(res.ok).toBe(true);

    // 档案与业务数据均被软删
    expect(mockDb.data.children[0].isDeleted).toBe(true);
    expect(mockDb.data.child_members[0].isDeleted).toBe(true);
    expect(mockDb.data.daily_records[0].isDeleted).toBe(true);
    expect(mockDb.data.todos[0].isDeleted).toBe(true);
  });
});

describe('childShare.convertTodoToRecord', () => {
  const todoSeed = (overrides = {}) => Object.assign({
    _id: 'tid1', uuid: 'todo-uuid-1', childId: 'c1', members: ['p1'],
    title: '背古诗', done: true, isDeleted: false, convertedRecordId: null,
  }, overrides);

  test('未完成待办不允许转换', async () => {
    setup(withOwnerMembership({ todos: [todoSeed({ done: false })] }), { OPENID: 'p1' });
    const res = await childShare.main({
      action: 'convertTodoToRecord',
      sourceTodoId: 'todo-uuid-1',
      record: { title: '背古诗' },
    });
    expect(res.ok).toBe(false);
    expect(res.error).toMatch(/已完成/);
  });

  test('首次转换生成确定性 ID 记录并回写待办', async () => {
    setup(withOwnerMembership({ todos: [todoSeed()] }), { OPENID: 'p1' });
    const res = await childShare.main({
      action: 'convertTodoToRecord',
      sourceTodoId: 'todo-uuid-1',
      record: { title: '背古诗', note: '完整背诵静夜思' },
    });
    expect(res.ok).toBe(true);
    expect(res.alreadyConverted).toBe(false);
    expect(res.record.uuid).toBe('todo_todo-uuid-1');
    expect(res.record.source).toBe('todo');
    // 记录已落库、待办已回写关联
    expect(mockDb.data.daily_records.find((r) => r._id === 'todo_todo-uuid-1')).toBeTruthy();
    expect(mockDb.data.todos[0].convertedRecordId).toBe('todo_todo-uuid-1');
  });

  test('已存在记录时幂等返回，不重复创建', async () => {
    setup(withOwnerMembership({
      todos: [todoSeed({ convertedRecordId: 'todo_todo-uuid-1' })],
      daily_records: [{ _id: 'todo_todo-uuid-1', uuid: 'todo_todo-uuid-1', childId: 'c1', isDeleted: false }],
    }), { OPENID: 'p1' });
    const res = await childShare.main({
      action: 'convertTodoToRecord',
      sourceTodoId: 'todo-uuid-1',
      record: { title: '背古诗' },
    });
    expect(res.ok).toBe(true);
    expect(res.alreadyConverted).toBe(true);
    // daily_records 仍只有一条
    expect(mockDb.data.daily_records).toHaveLength(1);
  });

  test('非成员无法操作他人待办', async () => {
    setup(withOwnerMembership({ todos: [todoSeed({ members: ['other'] })] }), { OPENID: 'p1' });
    const res = await childShare.main({
      action: 'convertTodoToRecord',
      sourceTodoId: 'todo-uuid-1',
      record: { title: '背古诗' },
    });
    expect(res.ok).toBe(false);
    expect(res.error).toMatch(/无权/);
  });
});

describe('childShare.getChildMembers', () => {
  test('成员可拿到该孩子权威 members(openid)', async () => {
    setup(withOwnerMembership({
      children: [
        { _id: 'ch1', uuid: 'c1', ownerId: 'p1', name: '小明', members: ['p1', 'p2'], isDeleted: false },
      ],
    }), { OPENID: 'p1' });
    const res = await childShare.main({ action: 'getChildMembers', childId: 'c1' });
    expect(res.ok).toBe(true);
    expect(res.members).toEqual(['p1', 'p2']);
  });

  test('非成员被拒，拿不到 members', async () => {
    setup(withOwnerMembership(), { OPENID: 'stranger' });
    const res = await childShare.main({ action: 'getChildMembers', childId: 'c1' });
    expect(res.ok).toBe(false);
    expect(res.error).toMatch(/无权/);
  });

  test('缺少 childId 时报错', async () => {
    setup(withOwnerMembership(), { OPENID: 'p1' });
    const res = await childShare.main({ action: 'getChildMembers' });
    expect(res.ok).toBe(false);
    expect(res.error).toMatch(/childId/);
  });
});
