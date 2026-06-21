import { UIAbility } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { RdbHelper } from '../database/RdbHelper'
import { ChipDao } from '../dao/ChipDao'
import { AppConstants } from '../constants/AppConstants'

const TAG = 'AIChip'

export default class EntryAbility extends UIAbility {
  private initPromise: Promise<void> | null = null

  onCreate(): void {
    hilog.info(0x0001, TAG, 'EntryAbility onCreate')
    this.initPromise = this.initApp()
  }

  private async initApp(): Promise<void> {
    const ctx = this.context
    await this.initDatabase(ctx)
    await this.runIntegrationTest(ctx)
  }

  private async initDatabase(ctx: Context): Promise<void> {
    try {
      const store = await RdbHelper.getStore(ctx)

      // 检查是否需要初始化
      let needInit = true
      try {
        const rs = await store.querySql("SELECT COALESCE(MAX(db_version), 0) as v FROM chips")
        if (rs.goToFirstRow()) {
          const v = rs.getLong(rs.getColumnIndex('v'))
          needInit = v < AppConstants.DB_VERSION
          hilog.info(0x0001, TAG, `DB v${v}, needInit=${needInit}`)
        }
        rs.close()
      } catch (e) {
        hilog.info(0x0001, TAG, 'Tables missing, full init needed')
      }

      if (needInit) {
        await this.fullInit(ctx, store)
      }
    } catch (e) {
      hilog.error(0x0001, TAG, `DB init failed: ${JSON.stringify(e)}`)
    }
  }

  private async fullInit(ctx: Context, store: relationalStore.RdbStore): Promise<void> {
    hilog.info(0x0001, TAG, 'Full DB init from seed_data.json')

    // 读 JSON 种子数据
    const raw = ctx.resourceManager.getRawFileContentSync('seed_data.json')
    const text = new util.TextDecoder('utf-8').decodeWithStream(raw, { stream: false })
    const seed = JSON.parse(text) as Record<string, Object>

    // CREATE TABLE（幂等）
    await store.executeSql(`CREATE TABLE IF NOT EXISTS manufacturers (
      id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE,
      country TEXT, website TEXT, sort_order INTEGER DEFAULT 0)`)
    await store.executeSql(`CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY, code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL, description TEXT, icon_name TEXT, sort_order INTEGER DEFAULT 0)`)
    await store.executeSql(`CREATE TABLE IF NOT EXISTS chips (
      id INTEGER PRIMARY KEY, name TEXT NOT NULL, model TEXT,
      manufacturer_id INTEGER NOT NULL, category_id INTEGER NOT NULL,
      architecture TEXT, process_node TEXT, release_date TEXT,
      key_specs_json TEXT, detail_specs_json TEXT, description TEXT,
      image_path TEXT, search_keywords TEXT,
      is_hot INTEGER DEFAULT 0, is_new INTEGER DEFAULT 0, is_deleted INTEGER DEFAULT 0,
      update_time INTEGER, db_version INTEGER DEFAULT 1)`)
    await store.executeSql('CREATE UNIQUE INDEX IF NOT EXISTS idx_chips_name_model ON chips(name, model)')
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_chips_category ON chips(category_id)')

    // INSERT 厂商
    const mfrs = seed['manufacturers'] as Array<Record<string, Object>>
    for (const m of mfrs) {
      await store.executeSql(
        'INSERT OR REPLACE INTO manufacturers (id,name,country,website,sort_order) VALUES (?,?,?,?,?)',
        [m['id'] as number, m['name'] as string, m['country'] as string, m['website'] as string, m['sort_order'] as number]
      )
    }

    // INSERT 分类
    const cats = seed['categories'] as Array<Record<string, Object>>
    for (const c of cats) {
      await store.executeSql(
        'INSERT OR REPLACE INTO categories (id,code,name,description,icon_name,sort_order) VALUES (?,?,?,?,?,?)',
        [c['id'] as number, c['code'] as string, c['name'] as string,
         c['description'] as string, c['icon_name'] as string, c['sort_order'] as number]
      )
    }

    // INSERT 芯片
    const chips = seed['chips'] as Array<Record<string, Object>>
    for (const ch of chips) {
      await store.executeSql(
        `INSERT OR REPLACE INTO chips (id,name,model,manufacturer_id,category_id,architecture,process_node,
         release_date,key_specs_json,detail_specs_json,description,image_path,search_keywords,
         is_hot,is_new,is_deleted,update_time,db_version)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
        [ch['id'] as number, ch['name'] as string, ch['model'] as string,
         ch['manufacturer_id'] as number, ch['category_id'] as number,
         ch['architecture'] as string, ch['process_node'] as string, ch['release_date'] as string,
         ch['key_specs_json'] as string, ch['detail_specs_json'] as string,
         ch['description'] as string, ch['image_path'] as string, ch['search_keywords'] as string,
         ch['is_hot'] as number, ch['is_new'] as number, ch['is_deleted'] as number,
         ch['update_time'] as number, ch['db_version'] as number]
      )
    }

    hilog.info(0x0001, TAG, `Seed loaded: ${mfrs.length} mfrs, ${cats.length} cats, ${chips.length} chips`)
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

      const r1 = await ChipDao.searchChips(ctx, '昇腾')
      hilog.info(0x0001, TAG, `Search '昇腾': ${r1.length} results`)
      const r2 = await ChipDao.searchChips(ctx, 'H100')
      hilog.info(0x0001, TAG, `Search 'H100': ${r2.length} results`)

      hilog.info(0x0001, TAG, 'Integration Test PASSED')
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
    if (this.initPromise) {
      this.initPromise.then(() => {
        windowStage.loadContent('pages/Index', (err) => {
          if (err.code) hilog.error(0x0001, TAG, 'Failed to load content: %{public}d', err.code)
        })
      })
    } else {
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) hilog.error(0x0001, TAG, 'Failed to load content: %{public}d', err.code)
      })
    }
  }
}
