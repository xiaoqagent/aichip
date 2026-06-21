import { AppConstants } from '../constants/AppConstants'

@Component
export struct MinePage {
  @State dbVersion: number = 0
  @State chipCount: number = 0

  build() {
    Column() {
      // 头部
      Column() {
        Image($r('app.media.app_icon'))
          .width(64)
          .height(64)
          .borderRadius(16)
          .margin({ top: 40 })

        Text(AppConstants.APP_NAME)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .margin({ top: 12 })

        Text(`v${AppConstants.APP_VERSION}`)
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 4 })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .padding({ bottom: 24 })

      // 信息列表
      List() {
        ListItem() {
          Row() {
            Text('数据库版本').fontSize(15).fontColor('#333')
            Blank()
            Text(`v${this.dbVersion}`).fontSize(15).fontColor('#999')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
        }

        ListItem() {
          Row() {
            Text('收录芯片').fontSize(15).fontColor('#333')
            Blank()
            Text(`${this.chipCount}款`).fontSize(15).fontColor('#999')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
        }
      }
      .layoutWeight(1)
      .margin({ top: 12 })

      // 底部
      Text('AI芯片查询对比APP')
        .fontSize(12)
        .fontColor('#CCC')
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }
}
