// tests/utils/todo.test.js —— 待办工具单测
const { todo, categoryMeta, TODO_CATEGORIES, DEFAULT_CATEGORY } = require('../../utils/todo');

describe('todo.categoryMeta', () => {
  test('命中已知分类返回对应元信息', () => {
    const meta = categoryMeta('作业');
    expect(meta.key).toBe('作业');
    expect(meta.emoji).toBeTruthy();
    expect(meta.color).toMatch(/^#/);
  });

  test('未知分类回落最后一项（其他）', () => {
    const meta = categoryMeta('不存在的分类');
    expect(meta).toBe(TODO_CATEGORIES[TODO_CATEGORIES.length - 1]);
  });

  test('默认分类在枚举内', () => {
    expect(TODO_CATEGORIES.some((c) => c.key === DEFAULT_CATEGORY)).toBe(true);
  });
});

describe('todo.listAll', () => {
  test('无当前孩子直接返回空', async () => {
    const out = await todo.listAll();
    expect(out).toEqual([]);
    expect(wx.cloud.callFunction).not.toHaveBeenCalled();
  });

  test('走 childShare.listTodos 成功时返回 todos', async () => {
    __setActiveChild('c1');
    const todos = [{ uuid: 't1', title: 'A' }, { uuid: 't2', title: 'B' }];
    wx.cloud.callFunction.mockImplementation(async ({ data }) => {
      expect(data).toEqual({ action: 'listTodos', childId: 'c1' });
      return { result: { ok: true, todos } };
    });
    const out = await todo.listAll();
    expect(out).toBe(todos);
  });

  test('listTodos 返回 ok:false 时回退前端分页查询（此处云不可用 → 空）', async () => {
    __setActiveChild('c1');
    wx.cloud.callFunction.mockImplementation(async () => ({ result: { ok: false, error: 'denied' } }));
    // 回退路径 db.listAllPaged 在无真实云环境下返回空数组（不抛错）
    const out = await todo.listAll();
    expect(Array.isArray(out)).toBe(true);
  });
});
