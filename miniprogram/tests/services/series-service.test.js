// tests/services/series-service.test.js —— 系列聚合 / 进度派生单测
// 重点覆盖 v3 需求：
//   - 「共 x 册」优先取 series.totalVolumes，未设置时回退分册数；
//   - 「已读 x」由分册 status==='done' 派生（重复「读完这册」不会重复计数）；
//   - groupBySeries / buildPanelVM 输出 progressPct。
const seriesService = require('../../services/series-service');

describe('series-service.deriveProgress 进度口径', () => {
  test('total 优先取 series.totalVolumes（运营口径「共 x 册」）', () => {
    const books = [
      { uuid: 'b1', seriesUuid: 's1', status: 'done' },
      { uuid: 'b2', seriesUuid: 's1', status: 'reading' },
    ];
    // 已添加 2 册，但系列声明共 8 册
    const p = seriesService.deriveProgress('s1', books, { totalVolumes: 8 });
    expect(p).toEqual({ done: 1, total: 8 });
  });

  test('totalVolumes 缺省(0/空)时回退为已归属分册数', () => {
    const books = [
      { uuid: 'b1', seriesUuid: 's1', status: 'done' },
      { uuid: 'b2', seriesUuid: 's1', status: 'done' },
      { uuid: 'b3', seriesUuid: 's1', status: 'want' },
    ];
    expect(seriesService.deriveProgress('s1', books, { totalVolumes: 0 })).toEqual({ done: 2, total: 3 });
    expect(seriesService.deriveProgress('s1', books)).toEqual({ done: 2, total: 3 });
  });

  test('done 由 status==="done" 派生：重复完成同一册不会重复计数（幂等）', () => {
    // 即便某册被多次「读完这册」打卡，books 里它仍只是一条 status:done 记录
    const books = [
      { uuid: 'b1', seriesUuid: 's1', status: 'done' },
      { uuid: 'b2', seriesUuid: 's1', status: 'done' },
    ];
    const p = seriesService.deriveProgress('s1', books, { totalVolumes: 10 });
    expect(p.done).toBe(2); // 不会因重复打卡变成 3、4...
    expect(p.total).toBe(10);
  });
});

describe('series-service.groupBySeries 输出', () => {
  test('系列卡片带 progress 与 progressPct（按 totalVolumes 计算百分比）', () => {
    const books = [
      { uuid: 'b1', seriesUuid: 's1', seriesIndex: 1, status: 'done', title: '第1册' },
      { uuid: 'b2', seriesUuid: 's1', seriesIndex: 2, status: 'done', title: '第2册' },
      { uuid: 'solo', status: 'reading', title: '单本书' },
    ];
    const seriesList = [{ uuid: 's1', name: '神奇校车', totalVolumes: 8 }];
    const { seriesCards, soloBooks } = seriesService.groupBySeries(books, seriesList);
    expect(soloBooks.map((b) => b.uuid)).toEqual(['solo']);
    expect(seriesCards).toHaveLength(1);
    const card = seriesCards[0];
    expect(card.isSeries).toBe(true);
    expect(card.progress).toEqual({ done: 2, total: 8 });
    expect(card.progressPct).toBe(25); // 2/8
  });
});

describe('series-service.buildPanelVM 输出', () => {
  test('面板进度同样以 totalVolumes 为分母', () => {
    const books = [
      { uuid: 'b1', seriesUuid: 's1', seriesIndex: 1, status: 'done' },
      { uuid: 'b2', seriesUuid: 's1', seriesIndex: 2, status: 'reading' },
    ];
    const seriesList = [{ uuid: 's1', name: '神奇校车', totalVolumes: 4 }];
    const vm = seriesService.buildPanelVM('s1', books, seriesList);
    expect(vm.name).toBe('神奇校车');
    expect(vm.progress).toEqual({ done: 1, total: 4 });
    expect(vm.progressPct).toBe(25);
    expect(vm.volumes.map((v) => v.indexLabel)).toEqual(['第1册', '第2册']);
  });
});
