import { CategoryModel } from '../model/CategoryModel'
import { ChipModel } from '../model/ChipModel'
import { CategoryDao } from '../dao/CategoryDao'
import { ChipDao } from '../dao/ChipDao'
import { ManufacturerDao } from '../dao/ManufacturerDao'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'AIChip'

interface SpecRow {
  name: string
  values: string[]
}

@Component
export struct ComparePage {
  @State categories: CategoryModel[] = []
  @State chips: ChipModel[] = []
  @State selectedCategory: CategoryModel | null = null
  @State selectedIds: Set<number> = new Set()
  @State isLoading: boolean = true
  @State showResult: boolean = false
  @State specRows: SpecRow[] = []
  @State comparedChips: ChipModel[] = []
  private context: Context = getContext()

  async aboutToAppear() {
    await ManufacturerDao.loadCache(this.context)
    this.loadCategories()
  }

  async loadCategories() {
    try {
      this.categories = await CategoryDao.getAll(this.context)
    } catch (e) {
      hilog.error(0x0001, TAG, `Load categories failed: ${JSON.stringify(e)}`)
    } finally {
      this.isLoading = false
    }
  }

  async onCategoryTap(cat: CategoryModel) {
    this.selectedCategory = cat
    this.selectedIds = new Set()
    this.showResult = false
    this.isLoading = true
    try {
      this.chips = await ChipDao.getByCategory(this.context, cat.code)
    } catch (e) {
      hilog.error(0x0001, TAG, `Load chips failed: ${JSON.stringify(e)}`)
      this.chips = []
    } finally {
      this.isLoading = false
    }
  }

  toggleChip(id: number) {
    const newSet = new Set(this.selectedIds)
    if (newSet.has(id)) {
      newSet.delete(id)
    } else {
      if (newSet.size >= 5) return
      newSet.add(id)
    }
    this.selectedIds = newSet
  }

  onCompare() {
    if (this.selectedIds.size < 2) return
    const selected = this.chips.filter(c => this.selectedIds.has(c.id))
    this.comparedChips = selected
    this.buildComparisonTable(selected)
    this.showResult = true
  }

  buildComparisonTable(chips: ChipModel[]) {
    // 用 key_specs_json 做对比：收集所有芯片的 key，合并到一张表
    const idToMfr = new Map<number, string>()
    const allKeys: string[] = []
    const seenKeys = new Set<string>()
    const chipSpecsList: Record<string, string>[] = []

    for (const chip of chips) {
      idToMfr.set(chip.id, ManufacturerDao.getName(chip.manufacturer_id))
      const parsed: Record<string, string> = {}
      try {
        const obj = JSON.parse(chip.key_specs_json) as Record<string, string>
        for (const k of Object.keys(obj)) {
          parsed[k] = obj[k]
          if (!seenKeys.has(k)) {
            seenKeys.add(k)
            allKeys.push(k)
          }
        }
      } catch (e) { /* ignore */ }
      chipSpecsList.push(parsed)
    }

    // 再加基础信息行
    this.specRows = [
      {
        name: '厂商',
        values: chips.map(c => idToMfr.get(c.id) || '未知')
      } as SpecRow,
      {
        name: '架构',
        values: chips.map(c => c.architecture || '-')
      } as SpecRow,
      {
        name: '制程',
        values: chips.map(c => c.process_node || '-')
      } as SpecRow,
      {
        name: '发布时间',
        values: chips.map(c => c.release_date || '-')
      } as SpecRow,
    ]

    for (const key of allKeys) {
      const row: SpecRow = {
        name: key,
        values: chipSpecsList.map(spec => spec[key] || '-')
      }
      this.specRows.push(row)
    }
  }

  onBack() {
    if (this.showResult) {
      this.showResult = false
    } else {
      this.selectedCategory = null
      this.chips = []
      this.selectedIds = new Set()
    }
  }

  getMfrName(id: number): string {
    return ManufacturerDao.getName(id)
  }

  build() {
    if (this.showResult) {
      this.CompareResultView()
    } else if (this.selectedCategory) {
      this.ChipSelectionView()
    } else {
      this.CategoryGridView()
    }
  }

  // ========== Phase 1: 分类选择 ==========
  @Builder CategoryGridView() {
    Column() {
      Text('选择芯片分类')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      if (this.isLoading) {
        LoadingProgress().width(24).height(24).margin({ top: 60 })
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

  // ========== Phase 2: 芯片选择 ==========
  @Builder ChipSelectionView() {
    Column() {
      // 标题栏
      Row() {
        Text('← 返回')
          .fontSize(14).fontColor('#1A73E8')
          .onClick(() => { this.onBack() })
        Text(this.selectedCategory!.name)
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          .layoutWeight(1).margin({ left: 8 })
        Text(`已选 ${this.selectedIds.size}/5`)
          .fontSize(13)
          .fontColor(this.selectedIds.size >= 2 ? '#1A73E8' : '#999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(24).height(24).margin({ top: 60 })
      } else if (this.chips.length === 0) {
        Column() {
          Text('该分类暂无芯片').fontSize(15).fontColor('#BFBFBF').margin({ top: 60 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        // 芯片列表（带复选框）
        List() {
          ForEach(this.chips, (chip: ChipModel) => {
            ListItem() {
              Row() {
                // 复选框
                Row() {
                  if (this.selectedIds.has(chip.id)) {
                    Text('✓')
                      .fontSize(14).fontColor('#FFFFFF')
                  }
                }
                .width(22).height(22)
                .borderRadius(4)
                .border({ width: 1.5, color: this.selectedIds.has(chip.id) ? '#1A73E8' : '#CCC' })
                .backgroundColor(this.selectedIds.has(chip.id) ? '#1A73E8' : Color.Transparent)
                .justifyContent(FlexAlign.Center)

                // 芯片名 + 型号
                Column() {
                  Text(chip.name)
                    .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
                  Text(chip.model)
                    .fontSize(12).fontColor('#999').margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 12 })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .backgroundColor('#FFFFFF')
              .borderRadius(6)
              .onClick(() => { this.toggleChip(chip.id) })
            }
            .margin({ left: 16, right: 16, top: 4, bottom: 4 })
          }, (chip: ChipModel) => `${chip.id}`)
        }
        .layoutWeight(1).margin({ top: 8 })
      }

      // 底部对比按钮
      Row() {
        Button(this.selectedIds.size < 2 ?
          `请选择至少2款芯片（已选${this.selectedIds.size}）` :
          `开始对比（${this.selectedIds.size}款）`)
          .width('100%').height(48)
          .fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(this.selectedIds.size >= 2 ? '#1A73E8' : '#CCC')
          .borderRadius(8)
          .enabled(this.selectedIds.size >= 2)
          .onClick(() => { this.onCompare() })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 16 })
      .backgroundColor('#FFFFFF')
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F6FA')
  }

  // ========== Phase 3: 对比结果表 ==========
  @Builder CompareResultView() {
    Column() {
      // 标题栏
      Row() {
        Text('← 重新选择')
          .fontSize(14).fontColor('#1A73E8')
          .onClick(() => { this.onBack() })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 水平滚动对比表
      Scroll() {
        Column() {
          // 表头行：芯片名称
          Row() {
            // 参数名列
            Text('参数')
              .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
              .width(72)
              .padding({ left: 12, top: 12, bottom: 12 })

            ForEach(this.comparedChips, (chip: ChipModel) => {
              Column() {
                Text(chip.name)
                  .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(chip.model)
                  .fontSize(11).fontColor('#999')
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 2 })
              }
              .width(140)
              .padding({ left: 10, right: 10, top: 10, bottom: 10 })
              .alignItems(HorizontalAlign.Start)
            })
          }
          .border({ width: { bottom: 1 }, color: '#E5E5E5' })

          // 数据行
          ForEach(this.specRows, (row: SpecRow, idx: number) => {
            Row() {
              Text(row.name)
                .fontSize(13).fontColor('#1A1A1A')
                .width(72)
                .padding({ left: 12, top: 10, bottom: 10 })

              ForEach(row.values, (val: string) => {
                Text(val)
                  .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
                  .width(140)
                  .padding({ left: 10, right: 10, top: 10, bottom: 10 })
              })
            }
            .backgroundColor(idx % 2 === 0 ? '#FAFBFC' : '#FFFFFF')
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Auto)
      .layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor('#FFFFFF')
  }
}
