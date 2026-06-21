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
      CREATE INDEX IF NOT EXISTS idx_chips_name ON chips(name);
      CREATE INDEX IF NOT EXISTS idx_chips_category ON chips(category_id);
      CREATE INDEX IF NOT EXISTS idx_chips_hot ON chips(is_hot);
    `
    const statements = ddl.split(';').map(s => s.trim()).filter(s => s.length > 0)
    for (const stmt of statements) {
      await store.executeSql(stmt)
    }
    hilog.info(0x0001, TAG, 'Tables created')

    // 种子数据在 Phase 7 通过 update_ai_chip_db.py 生成的 SQL 批量插入
    // Phase 1 仅验证表结构（为空是预期行为）
  }

  private async checkDbUpgrade(ctx: Context): Promise<void> {
    // 版本升级：读取 rawfile 中的 init_db.db 版本，比对本地的
    // Phase 1: 无数据无需升级，Phase 7 后再启用
    hilog.info(0x0001, TAG, `DB version: v${AppConstants.DB_VERSION}`)
  }

  private async runIntegrationTest(ctx: Context): Promise<void> {
    try {
      const store = await RdbHelper.getStore(ctx)
      hilog.info(0x0001, TAG, 'Database ready')

      // 验证表结构存在
      const catRs = await store.querySql("SELECT COUNT(*) as c FROM categories")
      let catCount = 0
      if (catRs.goToFirstRow()) {
        catCount = catRs.getLong(catRs.getColumnIndex('c'))
      }
      catRs.close()
      hilog.info(0x0001, TAG, `Categories table rows: ${catCount}`)

      const chipRs = await store.querySql("SELECT COUNT(*) as c FROM chips WHERE is_deleted = 0")
      let chipCount = 0
      if (chipRs.goToFirstRow()) {
        chipCount = chipRs.getLong(chipRs.getColumnIndex('c'))
      }
      chipRs.close()
      hilog.info(0x0001, TAG, `Chips table rows: ${chipCount}`)

      hilog.info(0x0001, TAG, 'Phase 1 Integration Test PASSED')
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
