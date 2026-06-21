import { CategoryModel } from '../model/CategoryModel'
import { ChipModel } from '../model/ChipModel'
import { CategoryDao } from '../dao/CategoryDao'
import { ChipDao } from '../dao/ChipDao'
import { ChipCard } from '../components/ChipCard'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { router } from '@kit.ArkUI'

const TAG = 'AIChip'

@Component
export struct CategoryPage {
  @State categories: CategoryModel[] = []
  @State chips: ChipModel[] = []
  @State selectedCategory: CategoryModel | null = null
  @State isLoading: boolean = true
  private context: Context = getContext()

  aboutToAppear() {
    this.loadCategories()
  }

  async loadCategories() {
    this.isLoading = true
    try {
      this.categories = await CategoryDao.getAll(this.context)
      hilog.info(0x0001, TAG, `Categories loaded: ${this.categories.length}`)
    } catch (e) {
      hilog.error(0x0001, TAG, `Load categories failed: ${JSON.stringify(e)}`)
    } finally {
      this.isLoading = false
    }
  }

  async onCategoryTap(cat: CategoryModel) {
    this.selectedCategory = cat
    this.isLoading = true
    try {
      this.chips = await ChipDao.getByCategory(this.context, cat.code)
      hilog.info(0x0001, TAG, `Category '${cat.code}': ${this.chips.length} chips`)
    } catch (e) {
      hilog.error(0x0001, TAG, `Load chips failed: ${JSON.stringify(e)}`)
      this.chips = []
    } finally {
      this.isLoading = false
    }
  }

  onBack() {
    this.selectedCategory = null
    this.chips = []
  }

  onChipClick(chip: ChipModel) {
    router.pushUrl({
      url: 'pages/ChipDetailPage',
      params: { chipId: chip.id, chipName: chip.name }
    })
  }

  build() {
    if (this.selectedCategory) {
      // 子页面：显示分类下的芯片列表
      this.ChipListView()
    } else {
      // 主界面：分类Grid
      this.CategoryGridView()
    }
  }

  @Builder ChipListView() {
    Column() {
      // 标题栏
      Row() {
        Image($r('sys.symbol.chevron_left'))
          .width(24).height(24).fillColor('#1A73E8')
          .onClick(() => { this.onBack() })
        Text(this.selectedCategory!.name)
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          .layoutWeight(1).margin({ left: 8 })
        Text(`${this.chips.length}款`)
          .fontSize(14).fontColor('#999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress()
          .width(24).height(24).margin({ top: 60 })
      } else if (this.chips.length === 0) {
        Column() {
          Image($r('app.media.app_icon'))
            .width(80).height(80).opacity(0.3)
          Text('暂无此分类的芯片数据')
            .fontSize(15).fontColor('#BFBFBF').margin({ top: 16 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.chips, (chip: ChipModel, index: number) => {
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
                Text(`${this.getChipCountHint(cat.code)}`)
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

  getChipCountHint(code: string): string {
    // 静态映射提示（实际数量在点击后由DB返回）
    const info: Record<string, string> = {
      'GPU': '点击查看GPU芯片',
      'NPU': '点击查看NPU芯片',
      'CPU': '点击查看CPU芯片',
      'TPU': '点击查看TPU芯片',
      'HBM': '点击查看HBM芯片',
      'FPGA': '点击查看FPGA芯片',
      'ASIC': '点击查看ASIC芯片',
      'DPU': '点击查看DPU芯片',
    }
    return info[code] || '点击查看'
  }
}
