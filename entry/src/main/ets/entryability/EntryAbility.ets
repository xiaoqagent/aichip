import { UIAbility } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
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

    // 首次安装 + 版本升级：从rawfile原子复制数据库到沙箱
    await this.initDatabase(ctx)

    // 集成测试
    await this.runIntegrationTest(ctx)
  }

  private async initDatabase(ctx: Context): Promise<void> {
    const dirPath = ctx.filesDir + '/databases'
    const dbPath = dirPath + '/' + AppConstants.DB_NAME
    const tmpPath = dirPath + '/init_db.tmp'

    // 确保目录存在
    if (!fs.accessSync(dirPath)) {
      fs.mkdirSync(dirPath, true)
    }

    const rawBytes: Uint8Array = await ctx.resourceManager.getRawFileContent(AppConstants.RAW_DB_PATH)

    // 首次安装：直接复制
    if (!fs.accessSync(dbPath)) {
      hilog.info(0x0001, TAG, 'First install, copying database')
      const file = fs.openSync(tmpPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
      fs.writeSync(file.fd, rawBytes.buffer as ArrayBuffer)
      fs.closeSync(file)
      fs.renameSync(tmpPath, dbPath)
      hilog.info(0x0001, TAG, 'Database initialized')
      return
    }

    // 版本升级检查：比对内置DB版本和沙箱DB版本
    const store = await RdbHelper.getStore(ctx)
    let sandboxVersion = 1
    try {
      const rs = await store.querySql('SELECT MAX(db_version) as v FROM chips')
      if (rs.goToFirstRow()) {
        sandboxVersion = rs.getLong(rs.getColumnIndex('v'))
      }
      rs.close()
    } catch (e) {
      hilog.warn(0x0001, TAG, 'Version read failed, assuming v1')
    }

    if (AppConstants.DB_VERSION > sandboxVersion) {
      hilog.info(0x0001, TAG, `DB upgrade: sandbox v${sandboxVersion} → rawfile v${AppConstants.DB_VERSION}`)
      await store.close()
      RdbHelper.close()

      // 原子覆盖
      const file = fs.openSync(tmpPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
      fs.writeSync(file.fd, rawBytes.buffer as ArrayBuffer)
      fs.closeSync(file)
      fs.renameSync(tmpPath, dbPath)

      await RdbHelper.getStore(ctx)
      hilog.info(0x0001, TAG, 'DB upgrade complete')
    } else {
      hilog.info(0x0001, TAG, `DB up to date: v${sandboxVersion}`)
    }
  }

  private async runIntegrationTest(ctx: Context): Promise<void> {
    try {
      const store = await RdbHelper.getStore(ctx)
      hilog.info(0x0001, TAG, 'Database ready')

      const categories = await CategoryDao.getAll(ctx)
      hilog.info(0x0001, TAG, `Categories: ${categories.length}`)

      const results = await ChipDao.searchChips(ctx, 'H100')
      hilog.info(0x0001, TAG, `Search H100: ${results.length} results`)

      const gpuChips = await ChipDao.getByCategory(ctx, 'GPU')
      hilog.info(0x0001, TAG, `GPU chips: ${gpuChips.length}`)

      const chip = await ChipDao.getById(ctx, 1)
      if (chip) {
        hilog.info(0x0001, TAG, `Chip #1: ${chip.name} (${chip.architecture})`)
      }

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
