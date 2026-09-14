// utils/todo.js —— 孩子待办（todos）云数据库操作封装
// 基于 utils/db.js 通用 CRUD 二次封装：自动带 ownerId + childId 归属过滤、
// 软删（isDeleted）、uuid 主键、毫秒时间戳（createdAt/updatedAt）。
// 与其他业务集合口径一致：待办强制关联当前孩子（withChild=true）。
//
// 文档字段（业务）：
//   title    {string}  待办标题（必填）
//   category {string}  分类：作业 / 生活 / 兴趣 / 其他
//   done     {boolean} 是否已完成
//   dueDate  {string}  截止日期 'YYYY-MM-DD'（选填，空表示不限）
//   remark   {string}  备注（选填）
//   completedAt {number|null} 最近一次完成时间
//   convertedRecordId {string|null} 由该待办生成的成长记录 uuid
// 通用层自动补：uuid / ownerId / childId / createdAt / updatedAt / isDeleted。

const db = require('./db');

const COL = db.COLLECTIONS.todos;

// 分类枚举（与页面顶部分类 chip、分类色令牌对齐；色值取自 app.wxss 马卡龙辅助色）
const TODO_CATEGORIES = [
  { key: '作业', emoji: '📖', color: '#8FC7F0' }, // sky
  { key: '生活', emoji: '🍚', color: '#7ED9C3' }, // mint
  { key: '兴趣', emoji: '🎨', color: '#B7A5F0' }, // lilac
  { key: '其他', emoji: '📌', color: '#FF9EB5' }, // pink
];

const DEFAULT_CATEGORY = '作业';

/** 取某分类的展示元信息（emoji / color），未命中回落「其他」 */
function categoryMeta(category) {
  return (
    TODO_CATEGORIES.find((c) => c.key === category) ||
    TODO_CATEGORIES[TODO_CATEGORIES.length - 1]
  );
}

const todo = {
  /** 当前孩子的全部待办（按创建时间倒序，分页拉全破 20 条上限） */
  async listAll() {
    const app = getApp();
    const childId = app && app.globalData && app.globalData.activeChildId;
    if (!childId) return [];
    try {
      const response = await wx.cloud.callFunction({
        name: 'childShare',
        data: { action: 'listTodos', childId },
      });
      const result = (response && response.result) || {};
      if (result.ok && Array.isArray(result.todos)) return result.todos;
      console.warn('[todo] childShare.listTodos 未成功，回退前端查询', result.error || result);
    } catch (err) {
      console.warn('[todo] childShare.listTodos 调用失败，回退前端查询', err);
    }
    return db.listAllPaged(COL, { orderBy: ['createdAt', 'desc'] });
  },

  /** 当前孩子某分类的待办（按创建时间倒序） */
  listByCategory(category) {
    return db.listAllPaged(COL, {
      where: { category },
      orderBy: ['createdAt', 'desc'],
    });
  },

  /**
   * 新增待办。归属（ownerId/childId）由通用层按当前 scope 自动补齐。
   * @param {object} item { title, category, dueDate?, remark? }
   */
  create(item) {
    return db.create(
      COL,
      Object.assign(
        {
          category: DEFAULT_CATEGORY,
          done: false,
          dueDate: null,
          remark: '',
          completedAt: null,
          convertedRecordId: null,
        },
        item
      )
    );
  },

  /** 按 uuid 更新（自动刷新 updatedAt） */
  update(uuid, patch) {
    return db.updateByUuid(COL, uuid, patch);
  },

  /** 勾选 / 取消完成；取消完成仅清完成时间，不删除已生成的成长记录。 */
  toggleDone(uuid, done) {
    return db.updateByUuid(COL, uuid, {
      done: !!done,
      completedAt: done ? Date.now() : null,
    });
  },

  /** 记录该待办已转换出的成长记录，防止重复创建。 */
  markConverted(uuid, recordUuid) {
    return db.updateByUuid(COL, uuid, { convertedRecordId: recordUuid });
  },

  /** 软删除 */
  remove(uuid) {
    return db.softDelete(COL, uuid);
  },
};

module.exports = {
  TODO_CATEGORIES,
  DEFAULT_CATEGORY,
  categoryMeta,
  todo,
};
