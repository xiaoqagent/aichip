import { router } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ChipModel } from '../model/ChipModel'
import { ChipDao } from '../dao/ChipDao'

const TAG = 'AIChip'

interface SpecItem { group: string; name: string; value: string; unit: string }
interface SpecGroup { group: string; items: SpecItem[] }

@Entry
@Component
struct ChipDetailPage {
  @State chip: ChipModel | null = null
  @State specGroups: SpecGroup[] = []
  @State isLoading: boolean = true
  private chipId: number = 0
  private context: Context = getContext()

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.chipId = params['chipId'] as number
    }
    this.loadChip()
  }

  async loadChip() {
    try {
      this.chip = await ChipDao.getById(this.context, this.chipId)
      if (this.chip) {
        this.parseSpecs(this.chip.detail_specs_json)
      }
    } catch (e) {
      hilog.error(0x0001, TAG, `Load failed: ${JSON.stringify(e)}`)
    } finally {
      this.isLoading = false
    }
  }

  parseSpecs(json: string) {
    const groups: Map<string, SpecItem[]> = new Map()
    try {
      const specs: SpecItem[] = JSON.parse(json) as SpecItem[]
      for (const s of specs) {
        if (!groups.has(s.group)) groups.set(s.group, [])
        groups.get(s.group)!.push(s)
      }
    } catch (e) { /* empty */ }
    this.specGroups = []
    groups.forEach((items, group) => {
      const sg: SpecGroup = { group, items }
      this.specGroups.push(sg)
    })
  }

  getMfrName(id: number): string {
    const m: Record<number, string> = {
      1:'NVIDIA', 2:'AMD', 3:'Intel', 4:'华为',
      5:'寒武纪', 6:'Google', 7:'SK海力士', 8:'三星'
    }
    return m[id] || '未知'
  }

  build() {
    Column() {
      this.HeaderBar()
      if (this.isLoading) {
        LoadingProgress().width(24).height(24).margin({ top: 60 })
      } else if (!this.chip) {
        Text('加载失败').fontSize(15).fontColor('#999').margin({ top: 60 })
      } else {
        Scroll() { this.DetailContent() }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
  }

  @Builder HeaderBar() {
    Row() {
      Text('← 返回').fontSize(14).fontColor('#1A73E8')
        .onClick(() => { router.back() })
      Text(this.chip?.name || '芯片详情')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        .layoutWeight(1).textAlign(TextAlign.Center)
      Text('').width(48)
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF')
  }

  @Builder DetailContent() {
    Column() {
      // ===== 芯片头部 =====
      Column() {
        Text(this.chip!.name)
          .fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        Text(this.chip!.model)
          .fontSize(16).fontColor('#666').margin({ top: 6 })
        Text(this.chip!.description)
          .fontSize(14).fontColor('#999').margin({ top: 8 })

        // 属性标签
        Row() {
          this.Tag('厂商', this.getMfrName(this.chip!.manufacturer_id))
          if (this.chip!.architecture) this.Tag('架构', this.chip!.architecture)
          if (this.chip!.process_node) this.Tag('制程', this.chip!.process_node)
          if (this.chip!.release_date) this.Tag('发布', this.chip!.release_date)
        }
        .width('100%').margin({ top: 16 })
      }
      .width('100%').padding(20).backgroundColor('#FFFFFF')

      // ===== 参数列表 =====
      ForEach(this.specGroups, (sg: SpecGroup) => {
        Column() {
          // 分组标题
          Row() {
            Text(sg.group)
              .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#1A73E8')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 8 })
          .backgroundColor('#FFFFFF')

          // 参数行（交替背景色）
          ForEach(sg.items, (item: SpecItem, idx: number) => {
            Row() {
              Text(item.name)
                .fontSize(14).fontColor('#666')
                .layoutWeight(1)
              Text(item.value + (item.unit ? ' ' + item.unit : ''))
                .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .backgroundColor(idx % 2 === 0 ? '#FAFBFC' : '#FFFFFF')
          })

          // 底部间隙
          Divider().color('#F0F0F0').strokeWidth(8)
        }
        .width('100%')
      })

      // 底部留白
      Column().width('100%').height(24)
    }
  }

  @Builder Tag(label: string, value: string) {
    Row() {
      Text(label).fontSize(11).fontColor('#999')
      Text(value).fontSize(11).fontColor('#333').margin({ left: 4 })
    }
    .padding({ left: 8, right: 10, top: 4, bottom: 4 })
    .backgroundColor('#F5F6FA').borderRadius(4)
    .margin({ right: 8, top: 6 })
  }
}
