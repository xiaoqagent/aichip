import { router } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ChipModel } from '../model/ChipModel'
import { ChipDao } from '../dao/ChipDao'
import { ManufacturerDao } from '../dao/ManufacturerDao'

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

  async aboutToAppear() {
    await ManufacturerDao.loadCache(this.context)
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.chipId = params['chipId'] as number
    }
    this.loadChip()
  }

  async loadChip() {
    try {
      this.chip = await ChipDao.getById(this.context, this.chipId)
      if (this.chip) this.parseSpecs(this.chip.detail_specs_json)
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
    } catch (e) { /* ignore malformed json */ }
    this.specGroups = []
    groups.forEach((items, group) => {
      const sg: SpecGroup = { group, items }
      this.specGroups.push(sg)
    })
  }

  getMfrName(id: number): string {
    return ManufacturerDao.getName(id)
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('← 返回').fontSize(14).fontColor('#1A73E8')
          .onClick(() => { router.back() })
        Blank()
        Text('').width(48)
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(24).height(24).margin({ top: 60 })
      } else if (!this.chip) {
        Text('加载失败').fontSize(15).fontColor('#999').margin({ top: 60 })
      } else {
        Scroll() {
          Column() {
            // ===== 芯片名称头部 =====
            Column() {
              Text(this.chip!.name)
                .fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
              Text(this.chip!.model)
                .fontSize(15).fontColor('#666').margin({ top: 4 })
              Text(this.chip!.description)
                .fontSize(13).fontColor('#999').margin({ top: 8 })
            }
            .width('100%').alignItems(HorizontalAlign.Start)
            .padding(20).backgroundColor('#FFFFFF')

            // ===== 基本信息（列表式） =====
            Column() {
              this.InfoRow('厂商', this.getMfrName(this.chip!.manufacturer_id), 0)
              if (this.chip!.architecture) this.InfoRow('架构', this.chip!.architecture, 1)
              if (this.chip!.process_node) this.InfoRow('制程', this.chip!.process_node, 2)
              if (this.chip!.release_date) this.InfoRow('发布时间', this.chip!.release_date, 3)
            }
            .width('100%').backgroundColor('#FFFFFF')
            .padding({ left: 20, right: 20, bottom: 8 })

            // 分隔线
            Divider().color('#F0F0F0').strokeWidth(8)

            // ===== 参数分组 =====
            ForEach(this.specGroups, (sg: SpecGroup) => {
              Column() {
                // 分组标题
                Text(sg.group)
                  .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#1A73E8')
                  .width('100%')
                  .padding({ left: 20, right: 20, top: 16, bottom: 10 })
                  .backgroundColor('#FFFFFF')

                // 参数行
                ForEach(sg.items, (item: SpecItem, idx: number) => {
                  Row() {
                    Text(item.name)
                      .fontSize(15).fontColor('#333')
                    Blank()
                    Text(item.value + (item.unit ? ' ' + item.unit : ''))
                      .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
                  }
                  .width('100%')
                  .backgroundColor(idx % 2 === 0 ? '#FAFBFC' : '#FFFFFF')
                  .padding({ left: 28, right: 20, top: 12, bottom: 12 })
                })

                Divider().color('#F0F0F0').strokeWidth(8)
              }
              .width('100%')
            })
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
  }

  @Builder InfoRow(label: string, value: string, idx: number) {
    Row() {
      Text(label)
        .fontSize(15).fontColor('#333')
      Blank()
      Text(value)
        .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
    }
    .width('100%')
    .backgroundColor(idx % 2 === 0 ? '#FAFBFC' : '#FFFFFF')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
  }
}
