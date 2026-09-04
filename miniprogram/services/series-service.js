// services/series-service.js —— 系列书（套书）聚合服务
// 职责：把扁平 books 按 seriesUuid 分组成「系列卡片 + 单本书」、构建系列面板 VM、
// 派生系列进度、推算下一册序号。纯读 + 纯算，不触库（数据由页面注入，保证可测试）。
// 对齐架构方案：series 只存元信息，已读册数由 books 聚合派生，不冗余存储。

const { BOOK_STATUS } = require('../utils/constants');

/**
 * 把书籍标签化：补 statusLabel / 展示封面（coverExternalUrl 优先，其次已水合的 coverUrl）。
 * @param {object} b 书籍
 */
function _decorate(b) {
  return Object.assign({}, b, {
    statusLabel: (BOOK_STATUS[b.status] || {}).label || '想读',
    coverUrl: b.coverExternalUrl || b.coverUrl || '',
  });
}

/**
 * 计算系列进度：已读(done)册数 / 现有分册数。
 * total 取当前已归属该系列的书籍数量（分册数），done 取其中 status==='done' 的数量。
 * @param {string} seriesUuid
 * @param {Array} books 全量书籍
 * @returns {{done:number, total:number}}
 */
function deriveProgress(seriesUuid, books) {
  const vols = (books || []).filter((b) => b && b.seriesUuid === seriesUuid);
  const done = vols.filter((b) => b.status === 'done').length;
  return { done, total: vols.length };
}

/**
 * 下一个 seriesIndex = 现有最大序号 + 1（无分册则从 1 起）。
 * @param {string} seriesUuid
 * @param {Array} books 全量书籍
 * @returns {number}
 */
function nextSeriesIndex(seriesUuid, books) {
  const idxs = (books || [])
    .filter((b) => b && b.seriesUuid === seriesUuid)
    .map((b) => Number(b.seriesIndex) || 0);
  return (idxs.length ? Math.max.apply(null, idxs) : 0) + 1;
}

/**
 * 将 books 按 seriesUuid 分组，返回「系列卡片」与「单本书」两部分。
 * - 归属某个有效系列（seriesList 中存在）的书 → 聚合进对应系列卡片；
 * - 其余（无 seriesUuid 或系列已不存在）→ 作为单本书展示。
 * @param {Array} books 全量书籍（建议已水合封面，含 coverUrl）
 * @param {Array} seriesList 系列元信息列表（含 uuid/name/totalVolumes）
 * @returns {{ seriesCards: Array, soloBooks: Array }}
 *   seriesCards: [{ isSeries:true, seriesUuid, name, totalVolumes, volumeCount,
 *                   volumes[], covers[], progress:{done,total}, updatedAt }]
 *   soloBooks:   [{ isSeries:false, ...book, statusLabel, coverUrl }]
 */
function groupBySeries(books, seriesList) {
  const list = Array.isArray(books) ? books : [];
  const seriesArr = Array.isArray(seriesList) ? seriesList : [];
  const seriesMap = {};
  seriesArr.forEach((s) => {
    if (s && s.uuid) seriesMap[s.uuid] = s;
  });

  const grouped = {}; // seriesUuid -> 分册书籍[]
  const soloBooks = [];
  list.forEach((b) => {
    if (b && b.seriesUuid && seriesMap[b.seriesUuid]) {
      (grouped[b.seriesUuid] = grouped[b.seriesUuid] || []).push(_decorate(b));
    } else if (b) {
      soloBooks.push(Object.assign({ isSeries: false }, _decorate(b)));
    }
  });

  const seriesCards = seriesArr
    .filter((s) => grouped[s.uuid] && grouped[s.uuid].length) // 仅展示已有分册的系列
    .map((s) => {
      const volumes = grouped[s.uuid]
        .slice()
        .sort((a, b) => (Number(a.seriesIndex) || 0) - (Number(b.seriesIndex) || 0));
      const progress = deriveProgress(s.uuid, list);
      // 叠层封面：取前 3 本的展示封面（外链或已水合链接），供卡片伪装堆叠
      const covers = volumes.slice(0, 3).map((v) => v.coverUrl || '');
      return {
        isSeries: true,
        seriesUuid: s.uuid,
        name: s.name || '未命名系列',
        totalVolumes: s.totalVolumes || volumes.length,
        volumeCount: volumes.length,
        volumes,
        covers,
        progress,
        updatedAt: Math.max.apply(null, [0].concat(volumes.map((v) => v.updatedAt || 0))),
      };
    });

  return { seriesCards, soloBooks };
}

/**
 * 构建系列面板 VM：分册按 seriesIndex 升序，含册序标签、状态标签与整体进度。
 * @param {string} seriesUuid
 * @param {Array} books 全量书籍
 * @param {Array} seriesList 系列元信息
 * @returns {object} { seriesUuid, name, totalVolumes, progress:{done,total}, volumes:[{...book, indexLabel, statusLabel}] }
 */
function buildPanelVM(seriesUuid, books, seriesList) {
  const meta = (seriesList || []).find((s) => s && s.uuid === seriesUuid);
  const volumes = (books || [])
    .filter((b) => b && b.seriesUuid === seriesUuid)
    .slice()
    .sort((a, b) => (Number(a.seriesIndex) || 0) - (Number(b.seriesIndex) || 0))
    .map((b) => {
      const d = _decorate(b);
      return Object.assign(d, {
        indexLabel: `第${b.seriesIndex || '?'}册`,
      });
    });
  return {
    seriesUuid,
    name: (meta && meta.name) || '未命名系列',
    totalVolumes: (meta && meta.totalVolumes) || volumes.length,
    progress: deriveProgress(seriesUuid, books),
    volumes,
  };
}

module.exports = {
  groupBySeries,
  buildPanelVM,
  deriveProgress,
  nextSeriesIndex,
};
