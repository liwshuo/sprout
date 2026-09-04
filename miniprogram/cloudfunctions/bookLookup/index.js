// cloudfunctions/bookLookup/index.js —— ISBN 查书：探数(tanshu) 主源 + Google Books 兜底
// 入参：event.isbn（13 位字符串）
// 逻辑：优先探数（需 TANSHU_KEY 环境变量，缺省则跳过）→ 兜底 Google Books
// 返回：{ found, title, author, cover, totalPages, isbn }；双源皆空返回 { found:false, isbn }
const cloud = require('wx-server-sdk');
const axios = require('axios');

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

// 请求超时（毫秒），避免云函数长时间挂起
const TIMEOUT = 8000;

/** 把封面链接的 http:// 归一为 https://（小程序 image 组件禁 http） */
function toHttps(url) {
  if (!url) return null;
  return String(url).replace(/^http:\/\//i, 'https://');
}

/** 转数字，非法返回 null */
function toNum(v) {
  if (v == null || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) && n > 0 ? n : null;
}

/**
 * 主源：探数 tanshu ISBN 查询。
 * 无 TANSHU_KEY 时直接返回 null（跳过，走兜底）。
 * 探数返回结构约定：{ code, msg, data: { title, author, img, pages, ... } }
 */
async function fromTanshu(isbn) {
  const key = process.env.TANSHU_KEY;
  if (!key) return null; // 未配置 key → 跳过主源
  try {
    const url = `https://api.tanshu.com/book/isbn?isbn=${isbn}&appKey=${key}`;
    const { data } = await axios.get(url, { timeout: TIMEOUT });
    const d = data && (data.data || data.result);
    const title = d && (d.title || d.name);
    if (!title) return null;
    return {
      title,
      author: d.author || null,
      cover: toHttps(d.img || d.cover || d.pic || d.photoUrl),
      totalPages: toNum(d.pages || d.page),
    };
  } catch (err) {
    console.warn('[bookLookup] tanshu 查询失败：', err && err.message);
    return null;
  }
}

/**
 * 兜底：Google Books ISBN 查询。
 * cover 取 volumeInfo.imageLinks.thumbnail，并把 http:// 替换为 https://。
 */
async function fromGoogle(isbn) {
  try {
    const url = `https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}`;
    const { data } = await axios.get(url, { timeout: TIMEOUT });
    const item = data && data.items && data.items[0];
    const info = item && item.volumeInfo;
    if (!info || !info.title) return null;
    const links = info.imageLinks || {};
    const thumb = links.thumbnail || links.smallThumbnail || null;
    return {
      title: info.title,
      author: (info.authors && info.authors.join(' / ')) || null,
      cover: toHttps(thumb),
      totalPages: toNum(info.pageCount),
    };
  } catch (err) {
    console.warn('[bookLookup] Google Books 查询失败：', err && err.message);
    return null;
  }
}

exports.main = async (event = {}) => {
  const isbn = String(event.isbn || '').trim();
  if (!isbn) return { found: false, isbn: '' };

  // 主源探数 → 兜底 Google Books
  let hit = await fromTanshu(isbn);
  if (!hit) hit = await fromGoogle(isbn);

  if (!hit || !hit.title) return { found: false, isbn };
  return {
    found: true,
    isbn,
    title: hit.title,
    author: hit.author || null,
    cover: hit.cover || null,
    totalPages: hit.totalPages || null,
  };
};
