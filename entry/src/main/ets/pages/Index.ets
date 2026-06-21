@Entry
@Component
struct Index {
  @State message: string = 'AI芯片';

  build() {
    Column() {
      Text(this.message)
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A73E8')
      Text('Hello World')
        .fontSize(20)
        .fontColor('#999')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F6FA')
  }
}
