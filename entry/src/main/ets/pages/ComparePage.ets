@Component
export struct ComparePage {
  build() {
    Column() {
      Image($r('app.media.app_icon'))
        .width(80)
        .height(80)
        .opacity(0.3)

      Text('芯片对比')
        .fontSize(18)
        .fontColor('#999')
        .margin({ top: 16 })

      Text('开发中，敬请期待...')
        .fontSize(14)
        .fontColor('#BFBFBF')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F6FA')
  }
}
