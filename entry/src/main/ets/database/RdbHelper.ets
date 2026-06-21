import { relationalStore } from '@kit.ArkData'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { AppConstants } from '../constants/AppConstants'

const TAG = 'AIChip'

export class RdbHelper {
  private static store: relationalStore.RdbStore | null = null

  static async getStore(context: Context): Promise<relationalStore.RdbStore> {
    if (RdbHelper.store) {
      return RdbHelper.store
    }
    const config: relationalStore.StoreConfig = {
      name: AppConstants.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }
    const store = await relationalStore.getRdbStore(context, config)
    RdbHelper.store = store
    return store
  }

  static async closeAndReopen(context: Context): Promise<relationalStore.RdbStore> {
    if (RdbHelper.store) {
      await RdbHelper.store.close()
      RdbHelper.store = null
    }
    const config: relationalStore.StoreConfig = {
      name: AppConstants.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }
    RdbHelper.store = await relationalStore.getRdbStore(context, config)
    return RdbHelper.store
  }

  static close(): void {
    if (RdbHelper.store) {
      RdbHelper.store.close()
      RdbHelper.store = null
    }
  }
}
