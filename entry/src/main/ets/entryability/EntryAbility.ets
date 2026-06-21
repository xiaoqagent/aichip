import { UIAbility } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { relationalStore } from '@kit.ArkData'
import { fileIo as fs } from '@kit.CoreFileKit'
import { RdbHelper } from '../database/RdbHelper'
import { ChipDao } from '../dao/ChipDao'
import { CategoryDao } from '../dao/CategoryDao'
import { AppConstants } from '../constants/AppConstants'

const TAG = 'AIChip'

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    hilog.info(0x0001, TAG, 'EntryAbility onCreate')
    this.initApp()
  }

  private async initApp(): Promise<void> {
    const ctx = this.context

    // 首次安装：直接用 SQL 建表 + 插入种子数据（避免文件路径不匹配）
    await this.initDatabase(ctx)

    // 集成测试
    await this.runIntegrationTest(ctx)
  }

  private async initDatabase(ctx: Context): Promise<void> {
    try {
      const store = await RdbHelper.getStore(ctx)

      // 检查 categories 表是否存在
      let tablesExist = false
      try {
        const rs = await store.querySql("SELECT COUNT(*) as c FROM categories")
        if (rs.goToFirstRow()) {
          const count = rs.getLong(rs.getColumnIndex('c'))
          tablesExist = count > 0
          hilog.info(0x0001, TAG, `Existing data: ${count} categories`)
        }
        rs.close()
      } catch (e) {
        hilog.info(0x0001, TAG, 'Tables not found, initializing from seed SQL')
      }

      if (!tablesExist) {
        await this.executeSeedSql(store)
        // 新装后也用rawfile全量覆盖，确保与内置数据库一致
        await this.checkDbUpgrade(ctx)
      } else {
        // 版本升级检查
        await this.checkDbUpgrade(ctx)
      }
    } catch (e) {
      hilog.error(0x0001, TAG, `DB init failed: ${JSON.stringify(e)}`)
    }
  }

  private async executeSeedSql(store: relationalStore.RdbStore): Promise<void> {
    hilog.info(0x0001, TAG, 'Creating tables from seed SQL')

    const ddl = `
      CREATE TABLE IF NOT EXISTS manufacturers (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
        country TEXT, website TEXT, sort_order INTEGER DEFAULT 0
      );
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL, description TEXT, icon_name TEXT, sort_order INTEGER DEFAULT 0
      );
      CREATE TABLE IF NOT EXISTS chips (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, model TEXT,
        manufacturer_id INTEGER NOT NULL, category_id INTEGER NOT NULL,
        architecture TEXT, process_node TEXT, release_date TEXT,
        key_specs_json TEXT, detail_specs_json TEXT, description TEXT,
        image_path TEXT, search_keywords TEXT,
        is_hot INTEGER DEFAULT 0, is_new INTEGER DEFAULT 0, is_deleted INTEGER DEFAULT 0,
        update_time INTEGER, db_version INTEGER DEFAULT 1,
        FOREIGN KEY (manufacturer_id) REFERENCES manufacturers(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      );
      CREATE UNIQUE INDEX IF NOT EXISTS idx_chips_name_model ON chips(name, model);
      CREATE INDEX IF NOT EXISTS idx_chips_name ON chips(name);
      CREATE INDEX IF NOT EXISTS idx_chips_category ON chips(category_id);
      CREATE INDEX IF NOT EXISTS idx_chips_hot ON chips(is_hot);
    `
    const statements = ddl.split(';').map(s => s.trim()).filter(s => s.length > 0)
    for (const stmt of statements) {
      await store.executeSql(stmt)
    }
    hilog.info(0x0001, TAG, 'Tables created')
  }

  private async insertSeedData(store: relationalStore.RdbStore): Promise<void> {
    const now = Date.now()

    // 厂商
    const mfrs: Array<Array<string | number>> = [
      [1, 'NVIDIA', '美国', 'https://www.nvidia.com', 1],
      [2, 'AMD', '美国', 'https://www.amd.com', 2],
      [3, 'Intel', '美国', 'https://www.intel.com', 3],
      [4, '华为', '中国', 'https://www.huawei.com', 4],
      [5, '寒武纪', '中国', 'https://www.cambricon.com', 5],
      [6, 'Google', '美国', 'https://cloud.google.com/tpu', 15],
      [7, 'SK海力士', '韩国', 'https://www.skhynix.com', 16],
      [8, '三星', '韩国', 'https://www.samsung.com', 17],
    ]
    for (const m of mfrs) {
      await store.executeSql(
        'INSERT OR IGNORE INTO manufacturers (id,name,country,website,sort_order) VALUES (?,?,?,?,?)',
        m.map(v => v.toString())
      )
    }

    // 分类
    const cats: Array<Array<string | number>> = [
      [1, 'GPU', 'GPU', '图形处理器', 'icon_gpu', 1],
      [2, 'NPU', 'NPU', '神经网络处理器', 'icon_npu', 2],
      [3, 'CPU', 'CPU', '中央处理器', 'icon_cpu', 3],
      [4, 'TPU', 'TPU', '张量处理器', 'icon_tpu', 4],
      [5, 'HBM', 'HBM', '高带宽内存', 'icon_hbm', 5],
      [6, 'FPGA', 'FPGA', '可编程门阵列', 'icon_fpga', 6],
      [7, 'ASIC', 'ASIC', '专用集成电路', 'icon_asic', 7],
      [8, 'DPU', 'DPU', '数据处理器', 'icon_dpu', 8],
    ]
    for (const c of cats) {
      await store.executeSql(
        'INSERT OR IGNORE INTO categories (id,code,name,description,icon_name,sort_order) VALUES (?,?,?,?,?,?)',
        c.map(v => v.toString())
      )
    }

    // 清理已有重复 + 插入种子数据
    await store.executeSql('DELETE FROM chips WHERE id NOT IN (SELECT MIN(id) FROM chips GROUP BY name, model)')

    // 测试芯片（指定ID，保证 INSERT OR IGNORE 幂等）
    interface SeedChip {
      id: number; n: string; m: string; mid: number; cid: number
      arch: string; node: string; rel: string
      key: string; kw: string; hot: number; nw: number
    }
    const chips: SeedChip[] = [
      { id:1, n:'H100', m:'H100 SXM5', mid:1, cid:1, arch:'Hopper', node:'4nm', rel:'2022-03',
        key:'{"显存":"80GB","FP16":"989 TFLOPS"}', kw:'H100,Hopper,80GB,NVIDIA', hot:1, nw:0 },
      { id:2, n:'昇腾910B', m:'Ascend 910B', mid:4, cid:2, arch:'DaVinci', node:'7nm', rel:'2023-08',
        key:'{"算力":"320 TFLOPS","TDP":"310W"}', kw:'910B,昇腾,Ascend,华为,NPU', hot:1, nw:0 },
      { id:3, n:'MI300X', m:'Instinct MI300X', mid:2, cid:1, arch:'CDNA3', node:'5nm', rel:'2023-12',
        key:'{"显存":"192GB","FP16":"1300 TFLOPS"}', kw:'MI300X,AMD,Instinct,192GB', hot:0, nw:1 },
      { id:4, n:'B200', m:'B200 SXM', mid:1, cid:1, arch:'Blackwell', node:'4nm', rel:'2024-03',
        key:'{"显存":"192GB","FP16":"2250 TFLOPS"}', kw:'B200,Blackwell,192GB,NVIDIA', hot:0, nw:1 },
      { id:5, n:'HBM3e', m:'HBM3e 24GB', mid:7, cid:5, arch:'', node:'', rel:'2024-01',
        key:'{"容量":"24GB","带宽":"1.2TB/s"}', kw:'HBM3e,SK海力士,HBM,24GB', hot:1, nw:1 },
    ]
    for (const c of chips) {
      await store.executeSql(
        `INSERT OR REPLACE INTO chips (id,name,model,manufacturer_id,category_id,architecture,process_node,
         release_date,key_specs_json,search_keywords,is_hot,is_new,update_time,db_version)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
        [c.id.toString(),c.n,c.m,c.mid.toString(),c.cid.toString(),c.arch,c.node,c.rel,
         c.key,c.kw,c.hot.toString(),c.nw.toString(),now.toString(),'2']
      )
    }
  }

  private async checkDbUpgrade(ctx: Context): Promise<void> {
    const rawVersion = AppConstants.DB_VERSION
    let sandboxVersion = 0

    try {
      const store = await RdbHelper.getStore(ctx)
      const rs = await store.querySql('SELECT COALESCE(MAX(db_version), 0) as v FROM chips')
      if (rs.goToFirstRow()) {
        sandboxVersion = rs.getLong(rs.getColumnIndex('v'))
      }
      rs.close()
    } catch (e) {
      sandboxVersion = 0
    }

    hilog.info(0x0001, TAG, `DB: sandbox v${sandboxVersion}, rawfile v${rawVersion}`)

    if (sandboxVersion >= rawVersion) {
      hilog.info(0x0001, TAG, `DB up to date: v${sandboxVersion}`)
      return
    }

    hilog.info(0x0001, TAG, `DB upgrade: sandbox v${sandboxVersion} → rawfile v${rawVersion}`)

    // Step 1: 关闭store
    RdbHelper.close()

    // Step 2: 读取rawfile
    const resMgr = ctx.resourceManager
    let rawBytes: Uint8Array = new Uint8Array(0)
    try {
      rawBytes = resMgr.getRawFileContentSync(AppConstants.RAW_DB_PATH)
      hilog.info(0x0001, TAG, `Rawfile read: ${rawBytes.length} bytes`)
    } catch (e) {
      hilog.error(0x0001, TAG, `Rawfile read failed: ${JSON.stringify(e)}`)
      return
    }

    // Step 3: 删旧库 + 写新库到精确路径
    try {
      // 删除旧store让系统释放文件句柄
      await relationalStore.deleteRdbStore(ctx, AppConstants.DB_NAME)
      hilog.info(0x0001, TAG, 'Old store deleted')
    } catch (e) {
      hilog.info(0x0001, TAG, 'No old store to delete')
    }

    // RdbStore内部路径: databaseDir/{bundleName}/entry/rdb/{name}
    const dbDir = ctx.databaseDir + '/aichip.xiaoq.profile/entry/rdb'
    const dbPath = dbDir + '/' + AppConstants.DB_NAME
    try {
      // 确保目录存在（用openSync CREATE会创建文件但不会创建父目录，需要先确保）
      if (!fs.accessSync(dbDir)) {
        // 递归创建目录 → 用逐级mkdir
        const parts = dbDir.split('/').filter(p => p.length > 0)
        let p = '/' + parts[0]
        for (let i = 1; i < parts.length; i++) {
          p += '/' + parts[i]
          try { fs.mkdirSync(p) } catch (e2) { /* 已存在 */ }
        }
      }
      const file = fs.openSync(dbPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC)
      fs.writeSync(file.fd, rawBytes.buffer as ArrayBuffer)
      fs.closeSync(file)
      hilog.info(0x0001, TAG, `DB file written: ${dbPath}`)
    } catch (e) {
      hilog.error(0x0001, TAG, `DB write failed: ${JSON.stringify(e)}`)
      return
    }

    // Step 4: 重新打开（会读取新文件）
    try {
      await RdbHelper.getStore(ctx)
      hilog.info(0x0001, TAG, 'DB upgrade: store reopened')
    } catch (e) {
      hilog.error(0x0001, TAG, `Store reopen failed: ${JSON.stringify(e)}`)
    }
  }

  private async runIntegrationTest(ctx: Context): Promise<void> {
    try {
      const store = await RdbHelper.getStore(ctx)
      hilog.info(0x0001, TAG, 'Database ready')

      const catRs = await store.querySql("SELECT COUNT(*) as c FROM categories")
      if (catRs.goToFirstRow()) {
        hilog.info(0x0001, TAG, `Categories: ${catRs.getLong(catRs.getColumnIndex('c'))}`)
      }
      catRs.close()

      const chipRs = await store.querySql("SELECT COUNT(*) as c FROM chips WHERE is_deleted = 0")
      if (chipRs.goToFirstRow()) {
        hilog.info(0x0001, TAG, `Chips: ${chipRs.getLong(chipRs.getColumnIndex('c'))}`)
      }
      chipRs.close()

      // Phase3: 验证真实搜索
      const r1 = await ChipDao.searchChips(ctx, '昇腾')
      hilog.info(0x0001, TAG, `Search '昇腾': ${r1.length} results`)

      const r2 = await ChipDao.searchChips(ctx, 'H100')
      hilog.info(0x0001, TAG, `Search 'H100': ${r2.length} results`)

      hilog.info(0x0001, TAG, 'Phase 3 Integration Test PASSED')
    } catch (e) {
      hilog.error(0x0001, TAG, `Integration Test FAILED: ${JSON.stringify(e)}`)
    }
  }

  onDestroy(): void {
    hilog.info(0x0001, TAG, 'EntryAbility onDestroy')
    RdbHelper.close()
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0001, TAG, 'onWindowStageCreate')
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0001, TAG, 'Failed to load content: %{public}d', err.code)
      }
    })
  }
}
