import { SearchBar } from '../components/SearchBar'
import { ChipCard } from '../components/ChipCard'
import { ChipModel } from '../model/ChipModel'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { router } from '@kit.ArkUI'

const TAG = 'AIChip'

// Phase2 验收用测试数据（DB为空时展示卡片布局）
const TEST_CHIPS: ChipModel[] = [
  { id: 1, name: 'H100', model: 'H100 SXM5', manufacturer_id: 1, category_id: 1,
    architecture: 'Hopper', process_node: '4nm', release_date: '2022-03',
    key_specs_json: '{"显存":"80GB","FP16":"989 TFLOPS"}', detail_specs_json: '[]',
    description: 'NVIDIA旗舰AI训练GPU', image_path: '', search_keywords: 'H100,Hopper',
    is_hot: 1, is_new: 0, is_deleted: 0, update_time: 1, db_version: 1 },
  { id: 2, name: '昇腾910B', model: 'Ascend 910B', manufacturer_id: 4, category_id: 2,
    architecture: 'DaVinci', process_node: '7nm', release_date: '2023-08',
    key_specs_json: '{"算力":"320 TFLOPS","TDP":"310W"}', detail_specs_json: '[]',
    description: '华为AI训练芯片', image_path: '', search_keywords: '910B,昇腾',
    is_hot: 1, is_new: 0, is_deleted: 0, update_time: 2, db_version: 1 },
  { id: 3, name: 'MI300X', model: 'Instinct MI300X', manufacturer_id: 2, category_id: 1,
    architecture: 'CDNA3', process_node: '5nm', release_date: '2023-12',
    key_specs_json: '{"显存":"192GB","FP16":"1300 TFLOPS"}', detail_specs_json: '[]',
    description: 'AMD旗舰AI芯片', image_path: '', search_keywords: 'MI300X,AMD',
    is_hot: 0, is_new: 1, is_deleted: 0, update_time: 3, db_version: 1 },
  { id: 4, name: 'B200', model: 'B200 SXM', manufacturer_id: 1, category_id: 1,
    architecture: 'Blackwell', process_node: '4nm', release_date: '2024-03',
    key_specs_json: '{"显存":"192GB","FP16":"2250 TFLOPS"}', detail_specs_json: '[]',
    description: 'NVIDIA Blackwell旗舰GPU', image_path: '', search_keywords: 'B200,Blackwell',
    is_hot: 0, is_new: 1, is_deleted: 0, update_time: 4, db_version: 1 },
  { id: 5, name: 'HBM3e', model: 'HBM3e 24GB', manufacturer_id: 7, category_id: 5,
    architecture: '', process_node: '', release_date: '2024-01',
    key_specs_json: '{"容量":"24GB","带宽":"1.2TB/s"}', detail_specs_json: '[]',
    description: 'SK海力士高带宽内存', image_path: '', search_keywords: 'HBM3e,SK海力士',
    is_hot: 1, is_new: 1, is_deleted: 0, update_time: 5, db_version: 1 }
]

@Component
export struct SearchPage {
  @State searchText: string = ''
  @State results: ChipModel[] = TEST_CHIPS  // Phase2: 展示测试数据
  private timerId: number = -1
  private searchCallCount: number = 0

  onSearch(keyword: string) {
    this.searchCallCount++
    hilog.info(0x0001, TAG, `Search called #${this.searchCallCount}: "${keyword}"`)

    if (keyword.length === 0) {
      this.results = TEST_CHIPS
      return
    }
    const kw = keyword.toLowerCase()
    this.results = TEST_CHIPS.filter(c =>
      c.name.toLowerCase().includes(kw) ||
      c.model.toLowerCase().includes(kw) ||
      c.search_keywords.toLowerCase().includes(kw)
    )
    hilog.info(0x0001, TAG, `Search results: ${this.results.length}`)
  }

  onTextChange(text: string) {
    this.searchText = text
    // 300ms防抖
    clearTimeout(this.timerId)
    this.timerId = setTimeout(() => {
      this.onSearch(text)
    }, 300)
  }

  onChipClick(chip: ChipModel) {
    hilog.info(0x0001, TAG, `Router to detail: chipId=${chip.id}`)
    router.pushUrl({
      url: 'pages/ChipDetailPage',
      params: { chipId: chip.id, chipName: chip.name }
    })
  }

  build() {
    Column() {
      SearchBar({ value: $searchText, onChange: this.onTextChange.bind(this) })

      if (this.searchText.length > 0 && this.results.length === 0) {
        // 空状态
        Column() {
          Image($r('app.media.app_icon'))
            .width(80).height(80).opacity(0.3)
          Text('未找到匹配的芯片')
            .fontSize(15).fontColor('#BFBFBF').margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 结果列表
        List() {
          ForEach(this.results, (chip: ChipModel, index: number) => {
            ListItem() {
              ChipCard({ chip: chip })
                .margin({ left: 16, right: 16, top: 4, bottom: 4 })
                .onClick(() => {
                  this.onChipClick(chip)
                })
            }
          }, (chip: ChipModel) => `${chip.id}_${chip.update_time}`)
        }
        .layoutWeight(1)
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }
}
