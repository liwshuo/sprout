# scripts —— 数据脚本与种子数据

本目录存放一次性数据脚本与云数据库种子数据。

## seed_book_library.json —— 官方精选书库种子数据

100 本分龄儿童书的 JSON 数组，用于初始化公共只读集合 `book_library`。

- **分龄覆盖**：`0-3` / `3-6` / `6-9` / `9-12` 各 25 本
- **类型覆盖**：`picture`（绘本）/ `bridge`（桥梁书）/ `chapter`（章节书）/ `science`（科普）
- **系列书**：`volumes[]` 内嵌分册（`{index, title, totalPages}`），系列 parent 与各分册 `totalPages` 均为 `null`
- **封面**：`coverExternalUrl` 暂留空字符串，前端走「色块 + 书名首字」兜底；后续可批量补 Open Library 封面（`https://covers.openlibrary.org/b/isbn/{isbn}-M.jpg`）

### 字段说明

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `uuid` | string | 书库条目主键（`bl-001` 递增） |
| `title` / `author` | string | 书名 / 作者 |
| `coverExternalUrl` | string | 封面外链，空串表示无（走兜底） |
| `ageRange` | string | `0-3` / `3-6` / `6-9` / `9-12` |
| `type` | string | `picture` / `bridge` / `chapter` / `science` |
| `isOfficial` | boolean | 是否官方精选（种子均为 `true`） |
| `volumes` | array | 系列分册 `[{index, title, totalPages}]`，单本为 `[]` |
| `totalPages` | number\|null | 单本总页数；系列书为 `null` |
| `description` | string | 一句话简介 |
| `tags` | array | 标签 |
| `addCount` / `likeCount` / `readFinishCount` | number | 热度计数（P1 起用，初始 0） |
| `createdAt` | string | ISO 时间戳 |

### 导入方式（微信云开发控制台）

1. 打开 **微信开发者工具 → 云开发控制台 → 数据库**
2. 新建集合 `book_library`
3. 集合 **权限设置** 选择「**所有人可读**」（仅管理员/后台可写）
   > `book_library` 为公共只读集合，无 `ownerId` / `childId` 归属字段；前端 `db.bookLibrary.listAll()` 不走归属过滤。
4. 选中集合 → **导入** → 选择本文件 `seed_book_library.json`
   - 冲突处理建议选择「**主键冲突时更新**」（若重复导入）
5. 导入完成后，在小程序「阅读」页点击「📚 精选书库」入口即可浏览。

> 提示：字段 `uuid` 建议作为业务主键使用；如需按 `uuid` 建索引可在控制台「索引管理」中添加，提升 `getByUuid` 查询效率。
