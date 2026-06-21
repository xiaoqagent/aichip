import { router } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ChipModel } from '../model/ChipModel'
import { ChipDao } from '../dao/ChipDao'
import { AppConstants } from '../constants/AppConstants'

const TAG = 'AIChip'

interface SpecItem {
  group: string
  name: string
  value: string
  unit: string
}

interface SpecGroup {
  group: string
  items: SpecItem[]
}

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
      hilog.info(0x0001, TAG, `ChipDetailPage: chipId=${this.chipId}`)
    }
    this.loadChip()
  }

  async loadChip() {
    try {
      this.chip = await ChipDao.getById(this.context, this.chipId)
      if (this.chip) {
        this.parseSpecs(this.chip.detail_specs_json)
        hilog.info(0x0001, TAG, `Loaded: ${this.chip.name}, specs: ${this.specGroups.length} groups`)
      }
    } catch (e) {
      hilog.error(0x0001, TAG, `Load chip failed: ${JSON.stringify(e)}`)
    } finally {
      this.isLoading = false
    }
  }

  parseSpecs(json: string) {
    const groups: Map<string, SpecItem[]> = new Map()
    try {
      const specs: SpecItem[] = JSON.parse(json) as SpecItem[]
      for (const s of specs) {
        if (!groups.has(s.group)) {
          groups.set(s.group, [])
        }
        groups.get(s.group)!.push(s)
      }
    } catch (e) {
      hilog.warn(0x0001, TAG, 'Spec parse failed, using empty')
    }

    this.specGroups = []
    groups.forEach((items, group) => {
      const sg: SpecGroup = { group, items }
      this.specGroups.push(sg)
    })
  }

  getMfrName(id: number): string {
    const info: Record<number, string> = {
      1:'NVIDIA', 2:'AMD', 3:'Intel', 4:'华为',
      5:'寒武纪', 6:'Google', 7:'SK海力士', 8:'三星'
    }
    return info[id] || '未知'
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('← 返回')
          .fontSize(14).fontColor('#1A73E8')
          .onClick(() => { router.back() })
        Text(this.chip?.name || '芯片详情')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text('').width(48)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress()
          .width(24).height(24).margin({ top: 60 })
      } else if (!this.chip) {
        Text('芯片数据加载失败')
          .fontSize(15).fontColor('#999').margin({ top: 60 })
      } else {
        Scroll() {
          Column() {
            // 芯片基本信息
            Column() {
              Text(this.chip.name)
                .fontSize(28).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
              Text(this.chip.model)
                .fontSize(16).fontColor('#666').margin({ top: 4 })
              Text(this.chip.description)
                .fontSize(14).fontColor('#999').margin({ top: 8 })

              // 属性标签行
              Row() {
                this.InfoTag('厂商', this.getMfrName(this.chip.manufacturer_id))
                if (this.chip.architecture) {
                  this.InfoTag('架构', this.chip.architecture)
                }
                if (this.chip.process_node) {
                  this.InfoTag('制程', this.chip.process_node)
                }
                if (this.chip.release_date) {
                  this.InfoTag('发布', this.chip.release_date)
                }
              }
              .width('100%')
              .margin({ top: 16 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')

            // 参数分组列表
            ForEach(this.specGroups, (sg: SpecGroup) => {
              Column() {
                Text(sg.group)
                  .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1A73E8')
                  .width('100%')
                  .padding({ top: 12, bottom: 8 })

                ForEach(sg.items, (item: SpecItem) => {
                  Row() {
                    Text(item.name)
                      .fontSize(14).fontColor('#666')
                    Blank()
                    Text(item.value + (item.unit ? ' ' + item.unit : ''))
                      .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
                  }
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
                })
              }
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 12 })
              .backgroundColor('#FFFFFF')
              .margin({ top: 8 })
            })
          }
        }
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder InfoTag(label: string, value: string) {
    Row() {
      Text(label).fontSize(11).fontColor('#999')
      Text(value).fontSize(11).fontColor('#333').margin({ left: 4 })
    }
    .padding({ left: 6, right: 8, top: 2, bottom: 2 })
    .backgroundColor('#F5F6FA')
    .borderRadius(4)
    .margin({ right: 6, top: 4 })
  }
}
