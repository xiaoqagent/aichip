import { relationalStore } from '@kit.ArkData'
import { CategoryModel } from '../model/CategoryModel'
import { RdbHelper } from '../database/RdbHelper'

export class CategoryDao {
  static async getAll(context: Context): Promise<CategoryModel[]> {
    const store = await RdbHelper.getStore(context)
    const rs = await store.querySql('SELECT * FROM categories ORDER BY sort_order ASC')
    const results: CategoryModel[] = []
    while (rs.goToNextRow()) {
      results.push({
        id: rs.getLong(rs.getColumnIndex('id')),
        code: rs.getString(rs.getColumnIndex('code')),
        name: rs.getString(rs.getColumnIndex('name')),
        description: rs.getString(rs.getColumnIndex('description')),
        icon_name: rs.getString(rs.getColumnIndex('icon_name')),
        sort_order: rs.getLong(rs.getColumnIndex('sort_order'))
      } as CategoryModel)
    }
    rs.close()
    return results
  }

  static async getByCode(context: Context, code: string): Promise<CategoryModel | null> {
    const store = await RdbHelper.getStore(context)
    const rs = await store.querySql(
      'SELECT * FROM categories WHERE code = ?',
      [code]
    )
    let result: CategoryModel | null = null
    if (rs.goToFirstRow()) {
      result = {
        id: rs.getLong(rs.getColumnIndex('id')),
        code: rs.getString(rs.getColumnIndex('code')),
        name: rs.getString(rs.getColumnIndex('name')),
        description: rs.getString(rs.getColumnIndex('description')),
        icon_name: rs.getString(rs.getColumnIndex('icon_name')),
        sort_order: rs.getLong(rs.getColumnIndex('sort_order'))
      } as CategoryModel
    }
    rs.close()
    return result
  }
}
