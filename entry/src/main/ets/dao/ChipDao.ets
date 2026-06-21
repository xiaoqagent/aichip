import { relationalStore } from '@kit.ArkData'
import { ChipModel } from '../model/ChipModel'
import { RdbHelper } from '../database/RdbHelper'

export class ChipDao {
  static async searchChips(context: Context, keyword: string): Promise<ChipModel[]> {
    const store = await RdbHelper.getStore(context)
    const likeKeyword = `%${keyword}%`
    const sql = `SELECT * FROM chips
      WHERE is_deleted = 0
        AND (name LIKE ? OR model LIKE ? OR search_keywords LIKE ?)
      ORDER BY is_hot DESC, name ASC
      LIMIT 50`
    const rs = await store.querySql(sql, [likeKeyword, likeKeyword, likeKeyword])
    const results = parseResultSet(rs)
    rs.close()
    return results
  }

  static async getById(context: Context, id: number): Promise<ChipModel | null> {
    const store = await RdbHelper.getStore(context)
    const rs = await store.querySql(
      `SELECT * FROM chips WHERE id = ? AND is_deleted = 0`,
      [id.toString()]
    )
    const result = parseResultSet(rs)
    rs.close()
    return result.length > 0 ? result[0] : null
  }

  static async getByCategory(context: Context, categoryCode: string): Promise<ChipModel[]> {
    const store = await RdbHelper.getStore(context)
    const rs = await store.querySql(
      `SELECT c.* FROM chips c
       INNER JOIN categories cat ON c.category_id = cat.id
       WHERE cat.code = ? AND c.is_deleted = 0
       ORDER BY c.is_hot DESC, c.release_date DESC`,
      [categoryCode]
    )
    const results = parseResultSet(rs)
    rs.close()
    return results
  }
}

function parseResultSet(rs: relationalStore.ResultSet): ChipModel[] {
  const results: ChipModel[] = []
  while (rs.goToNextRow()) {
    results.push({
      id: rs.getLong(rs.getColumnIndex('id')),
      name: rs.getString(rs.getColumnIndex('name')),
      model: rs.getString(rs.getColumnIndex('model')),
      manufacturer_id: rs.getLong(rs.getColumnIndex('manufacturer_id')),
      category_id: rs.getLong(rs.getColumnIndex('category_id')),
      architecture: rs.getString(rs.getColumnIndex('architecture')),
      process_node: rs.getString(rs.getColumnIndex('process_node')),
      release_date: rs.getString(rs.getColumnIndex('release_date')),
      key_specs_json: rs.getString(rs.getColumnIndex('key_specs_json')),
      detail_specs_json: rs.getString(rs.getColumnIndex('detail_specs_json')),
      description: rs.getString(rs.getColumnIndex('description')),
      image_path: rs.getString(rs.getColumnIndex('image_path')),
      search_keywords: rs.getString(rs.getColumnIndex('search_keywords')),
      is_hot: rs.getLong(rs.getColumnIndex('is_hot')),
      is_new: rs.getLong(rs.getColumnIndex('is_new')),
      is_deleted: rs.getLong(rs.getColumnIndex('is_deleted')),
      update_time: rs.getLong(rs.getColumnIndex('update_time')),
      db_version: rs.getLong(rs.getColumnIndex('db_version'))
    } as ChipModel)
  }
  return results
}
