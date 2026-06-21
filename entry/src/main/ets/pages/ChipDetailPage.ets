import { router } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'AIChip'

@Entry
@Component
struct ChipDetailPage {
  @State chipId: number = 0
  @State chipName: string = ''

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.chipId = params['chipId'] as number
      this.chipName = params['chipName'] as string
    }
    hilog.info(0x0001, TAG, `ChipDetailPage: chipId=${this.chipId}, name=${this.chipName}`)
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.symbol.chevron_left'))
          .width(24).height(24).fillColor('#1A73E8')
          .onClick(() => { router.back() })
        Text(this.chipName || '芯片详情')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text('').width(24)  // 占位平衡
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      Column() {
        Image($r('app.media.app_icon'))
          .width(120).height(120).opacity(0.3)
        Text(`chipId: ${this.chipId}`)
          .fontSize(16).fontColor('#666').margin({ top: 16 })
        Text('详细参数将在 Phase 5 实现')
          .fontSize(14).fontColor('#999').margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }
}
