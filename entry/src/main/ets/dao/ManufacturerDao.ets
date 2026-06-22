import { relationalStore } from '@kit.ArkData'
import { RdbHelper } from '../database/RdbHelper'

interface Manufacturer {
  id: number
  name: string
  country: string
}

export class ManufacturerDao {
  // 内存缓存，避免每次重复查DB
  private static cache: Map<number, string> = new Map()
  private static loaded: boolean = false

  static async loadCache(context: Context): Promise<void> {
    if (ManufacturerDao.loaded) return
    try {
      const store = await RdbHelper.getStore(context)
      const rs = await store.querySql('SELECT id, name FROM manufacturers ORDER BY sort_order')
      while (rs.goToNextRow()) {
        ManufacturerDao.cache.set(rs.getLong(0), rs.getString(1))
      }
      rs.close()
      ManufacturerDao.loaded = true
    } catch (e) {
      // 如果 manufacturers 表还不存在，稍后重试
    }
  }

  static getName(id: number): string {
    return ManufacturerDao.cache.get(id) || '未知'
  }

  static isLoaded(): boolean {
    return ManufacturerDao.loaded
  }
}
