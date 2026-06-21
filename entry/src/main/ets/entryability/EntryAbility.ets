import { UIAbility } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { relationalStore } from '@kit.ArkData'
import { fileIo as fs } from '@kit.CoreFileKit'
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
      // 🔧 修复2: 直接用 rawfile 覆盖，不建空表不写种子
      await this.upgradeFromRawfile(ctx)
    } catch (e) {
      hilog.error(0x0001, TAG, `DB init failed: ${JSON.stringify(e)}`)
    }
  }

  private async upgradeFromRawfile(ctx: Context): Promise<void> {
    // 读 rawfile
    const resMgr = ctx.resourceManager
    let rawBytes: Uint8Array = new Uint8Array(0)
    try {
      rawBytes = resMgr.getRawFileContentSync(AppConstants.RAW_DB_PATH)
      hilog.info(0x0001, TAG, `Rawfile: ${rawBytes.length} bytes`)
    } catch (e) {
      hilog.error(0x0001, TAG, `Rawfile read failed: ${JSON.stringify(e)}`)
      return
    }

    // 检查是否需要升级
    let needUpgrade = true
    try {
      const store = await RdbHelper.getStore(ctx)
      try {
        const rs = await store.querySql('SELECT COALESCE(MAX(db_version), 0) as v FROM chips')
        if (rs.goToFirstRow()) {
          const v = rs.getLong(rs.getColumnIndex('v'))
          if (v >= AppConstants.DB_VERSION) {
            needUpgrade = false
            hilog.info(0x0001, TAG, `DB up to date: v${v}`)
          } else {
            hilog.info(0x0001, TAG, `DB upgrade needed: sandbox v${v} → rawfile v${AppConstants.DB_VERSION}`)
          }
        }
        rs.close()
      } catch (e) {
        // 表不存在，需要升级
        hilog.info(0x0001, TAG, 'Tables missing, upgrade needed')
      }
    } catch (e) {
      hilog.info(0x0001, TAG, 'Store not ready, upgrade needed')
    }

    if (!needUpgrade) {
      return
    }

    // 关闭旧 store
    RdbHelper.close()

    // 删旧库（ctx.databaseDir 已含 bundleName）
    try {
      await relationalStore.deleteRdbStore(ctx, AppConstants.DB_NAME)
    } catch (e) {
      // 首次安装时不存在
    }

    // 🔧 修复3: ctx.databaseDir 已经包含 bundleName，不用再加
    const rdbDir = ctx.databaseDir + '/entry/rdb'
    const dbPath = rdbDir + '/' + AppConstants.DB_NAME

    // 确保目录存在
    try {
      if (!fs.accessSync(rdbDir)) {
        let p = ''
        for (const part of rdbDir.split('/').filter(s => s.length > 0)) {
          p += '/' + part
          try { fs.mkdirSync(p) } catch (e2) { /* 已存在 */ }
        }
      }
    } catch (e) {
      hilog.info(0x0001, TAG, 'Dir check skipped')
    }

    // 写入 rawfile 到 RdbStore 精确路径
    try {
      const file = fs.openSync(dbPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC)
      fs.writeSync(file.fd, rawBytes.buffer as ArrayBuffer)
      fs.closeSync(file)
      hilog.info(0x0001, TAG, `DB file written: ${rawBytes.length}B → ${dbPath}`)
    } catch (e) {
      hilog.error(0x0001, TAG, `DB write failed: ${JSON.stringify(e)}`)
      return
    }

    // 重开 store
    try {
      await RdbHelper.getStore(ctx)
      hilog.info(0x0001, TAG, 'DB reopened after upgrade')
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
    // 🔧 修复1: 等 DB 就绪后再渲染页面
    if (this.initPromise) {
      this.initPromise.then(() => {
        windowStage.loadContent('pages/Index', (err) => {
          if (err.code) {
            hilog.error(0x0001, TAG, 'Failed to load content: %{public}d', err.code)
          }
        })
      })
    } else {
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(0x0001, TAG, 'Failed to load content: %{public}d', err.code)
        }
      })
    }
  }
}
