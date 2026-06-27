import { CategoryModel } from '../model/CategoryModel'
import { ChipModel } from '../model/ChipModel'
import { CategoryDao } from '../dao/CategoryDao'
import { ChipDao } from '../dao/ChipDao'
import { ManufacturerDao } from '../dao/ManufacturerDao'
import { RdbHelper } from '../database/RdbHelper'
import { ChipCard } from '../components/ChipCard'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { router } from '@kit.ArkUI'

const TAG = 'AIChip'

type SortMode = 'default' | 'date' | 'hot'
interface MfrItem {
  id: number
  name: string
}

@Component
export struct CategoryPage {
  @State categories: CategoryModel[] = []
  @State allChips: ChipModel[] = []
  @State filteredChips: ChipModel[] = []
  @State selectedCategory: CategoryModel | null = null
  @State isLoading: boolean = true
  @State sortMode: SortMode = 'default'
  @State filterMfrId: number = 0 // 0=全部
  private chipCountMap: Map<number, number> = new Map()
  private chipCache: Map<string, ChipModel[]> = new Map()
  private context: Context = getContext()

  async aboutToAppear() {
    await ManufacturerDao.loadCache(this.context)
    this.loadCategories()
  }

  async loadCategories() {
    try {
      this.categories = await CategoryDao.getAll(this.context)
      hilog.info(0x0001, TAG, `Categories loaded: ${this.categories.length}`)
      // 加载每类芯片数量
      await this.loadChipCounts()
    } catch (e) {
      hilog.error(0x0001, TAG, `Load categories failed: ${JSON.stringify(e)}`)
    } finally {
      this.isLoading = false
    }
  }

  async loadChipCounts() {
    const store = await RdbHelper.getStore(this.context)
    const rs = await store.querySql(
      'SELECT category_id, COUNT(*) as c FROM chips WHERE is_deleted=0 GROUP BY category_id'
    )
    while (rs.goToNextRow()) {
      this.chipCountMap.set(rs.getLong(0), rs.getLong(1))
    }
    rs.close()
  }

  async onCategoryTap(cat: CategoryModel) {
    this.selectedCategory = cat
    this.sortMode = 'default'
    this.filterMfrId = 0

    // 缓存：同一个分类不重复查DB
    if (this.chipCache.has(cat.code)) {
      this.allChips = this.chipCache.get(cat.code)!
      hilog.info(0x0001, TAG, `Category '${cat.code}': cache hit, ${this.allChips.length} chips`)
    } else {
      this.isLoading = true
      try {
        this.allChips = await ChipDao.getByCategory(this.context, cat.code)
        this.chipCache.set(cat.code, this.allChips)
        hilog.info(0x0001, TAG, `Category '${cat.code}': DB loaded, ${this.allChips.length} chips`)
      } catch (e) {
        hilog.error(0x0001, TAG, `Load chips failed: ${JSON.stringify(e)}`)
        this.allChips = []
      } finally {
        this.isLoading = false
      }
    }
    this.applyFilterAndSort()
  }

  applyFilterAndSort() {
    let list = [...this.allChips]

    // 厂商筛选
    if (this.filterMfrId > 0) {
      list = list.filter(c => c.manufacturer_id === this.filterMfrId)
    }

    // 排序
    if (this.sortMode === 'date') {
      list.sort((a, b) => b.release_date.localeCompare(a.release_date))
    } else if (this.sortMode === 'hot') {
      list.sort((a, b) => b.is_hot - a.is_hot)
    }

    this.filteredChips = list
  }

  onSortChange(mode: SortMode) {
    this.sortMode = mode
    this.applyFilterAndSort()
  }

  onMfrFilter(mfrId: number) {
    this.filterMfrId = mfrId
    this.applyFilterAndSort()
  }

  getMfrName(mfrId: number): string {
    return ManufacturerDao.getName(mfrId)
  }

  getDistinctMfrs(): MfrItem[] {
    const seen = new Set<number>()
    const result: MfrItem[] = []
    for (const c of this.allChips) {
      if (!seen.has(c.manufacturer_id)) {
        seen.add(c.manufacturer_id)
        const item: MfrItem = { id: c.manufacturer_id, name: this.getMfrName(c.manufacturer_id) }
        result.push(item)
      }
    }
    return result
  }

  onBack() {
    this.selectedCategory = null
    this.allChips = []
    this.filteredChips = []
  }

  onChipClick(chip: ChipModel) {
    router.pushUrl({
      url: 'pages/ChipDetailPage',
      params: { chipId: chip.id, chipName: chip.name }
    })
  }

  build() {
    if (this.selectedCategory) {
      this.ChipListView()
    } else {
      this.CategoryGridView()
    }
  }

  @Builder ChipListView() {
    Column() {
      // 标题栏 + 返回按钮
      Row() {
        Text('← 返回')
          .fontSize(14).fontColor('#1A73E8')
          .onClick(() => { this.onBack() })
        Text(this.selectedCategory!.name)
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          .layoutWeight(1).margin({ left: 8 })
        Text(`${this.filteredChips.length}款`)
          .fontSize(14).fontColor('#999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // 排序栏
      Row() {
        Text(this.sortMode === 'default' ? '✓ 默认' : '默认')
          .fontSize(12)
          .fontColor(this.sortMode === 'default' ? '#1A73E8' : '#999')
          .onClick(() => { this.onSortChange('default') })
        Text(this.sortMode === 'date' ? '✓ 日期' : '日期')
          .fontSize(12)
          .fontColor(this.sortMode === 'date' ? '#1A73E8' : '#999')
          .margin({ left: 12 })
          .onClick(() => { this.onSortChange('date') })
        Text(this.sortMode === 'hot' ? '✓ 热度' : '热度')
          .fontSize(12)
          .fontColor(this.sortMode === 'hot' ? '#1A73E8' : '#999')
          .margin({ left: 12 })
          .onClick(() => { this.onSortChange('hot') })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })
      .justifyContent(FlexAlign.End)
      .backgroundColor('#FFFFFF')

      // 厂商筛选（横向滚动）
      Scroll() {
        Row() {
          ForEach(this.getDistinctMfrs(), (mfr: MfrItem) => {
            Text(mfr.name)
              .fontSize(12)
              .fontColor(this.filterMfrId === mfr.id ? '#FFFFFF' : '#666')
              .backgroundColor(this.filterMfrId === mfr.id ? '#1A73E8' : '#F0F0F0')
              .borderRadius(12)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .margin({ right: 6 })
              .onClick(() => {
                this.onMfrFilter(this.filterMfrId === mfr.id ? 0 : mfr.id)
              })
          })
        }
        .padding({ left: 16, right: 16, top: 4, bottom: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .backgroundColor('#FFFFFF')

      // 芯片列表
      if (this.isLoading) {
        LoadingProgress()
          .width(24).height(24).margin({ top: 60 })
      } else if (this.filteredChips.length === 0) {
        Column() {
          Image($r('app.media.app_icon'))
            .width(80).height(80).opacity(0.3)
          Text('暂无匹配的芯片')
            .fontSize(15).fontColor('#BFBFBF').margin({ top: 16 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.filteredChips, (chip: ChipModel, index: number) => {
            ListItem() {
              ChipCard({ chip: chip })
                .margin({ left: 16, right: 16, top: 4, bottom: 4 })
                .onClick(() => { this.onChipClick(chip) })
            }
          }, (chip: ChipModel) => `${chip.id}_${chip.update_time}`)
        }
        .layoutWeight(1).margin({ top: 8 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder CategoryGridView() {
    Column() {
      Text('芯片分类')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      if (this.isLoading) {
        LoadingProgress()
          .width(24).height(24).margin({ top: 60 })
      } else {
        Grid() {
          ForEach(this.categories, (cat: CategoryModel) => {
            GridItem() {
              Column() {
                Text(cat.name)
                  .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#1A73E8')
                Text(cat.description)
                  .fontSize(12).fontColor('#999').margin({ top: 4 })
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.chipCountMap.get(cat.id) ?? 0}款芯片`)
                  .fontSize(11).fontColor('#BFBFBF').margin({ top: 6 })
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => { this.onCategoryTap(cat) })
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .padding({ left: 16, right: 16 })
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F6FA')
  }
}
