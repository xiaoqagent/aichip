import { AppConstants } from '../constants/AppConstants'
import { router } from '@kit.ArkUI'

@Component
export struct MinePage {
  @State dbVersion: number = 11
  @State chipCount: number = 177

  build() {
    Column() {
      // 头部
      Column() {
        Image($r('app.media.app_icon'))
          .width(72).height(72).borderRadius(16).margin({ top: 40 })

        Text(AppConstants.APP_NAME)
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ top: 14 })
        Text(`v${AppConstants.APP_VERSION}`)
          .fontSize(14).fontColor('#1A1A1A').margin({ top: 6 })
      }
      .width('100%')
      .padding({ bottom: 28 })
      .backgroundColor('#FFFFFF')

      // 数据概览
      Column() {
        this.MenuRow('数据库版本', `v${this.dbVersion}`)
        this.MenuRow('收录芯片', `${this.chipCount} 款`, true)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .margin({ top: 12 })

      // 数据库更新记录
      Column() {
        Text('更新记录')
          .fontSize(13).fontColor('#1A1A1A')
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 8 })

        Column() {
          this.UpdateLogRow('2026-06-27', 'V3', '新增对比功能，优化分类数量显示，界面精简')
          this.UpdateLogRow('2026-06-22', 'V2', '新增138款，总计177款芯片，覆盖30个厂商，11个大类')
          this.UpdateLogRow('2026-06-21', 'V1', '收录30款芯片，覆盖6个大类、12家厂商')
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .borderRadius(8)
        .margin({ left: 16, right: 16 })
      }
      .width('100%')
      .margin({ top: 12 })

      // 设置项
      Column() {
        Row() {
          Text('用户协议').fontSize(15).fontColor('#1A1A1A')
          Blank()
          Image($r('sys.symbol.chevron_right'))
            .width(16).height(16).fillColor('#CCC')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .onClick(() => {
          router.pushUrl({ url: 'pages/UserAgreementPage' })
        })

        Divider().color('#F5F5F5').strokeWidth(0.5).margin({ left: 16 })

        Row() {
          Text('隐私政策').fontSize(15).fontColor('#1A1A1A')
          Blank()
          Image($r('sys.symbol.chevron_right'))
            .width(16).height(16).fillColor('#CCC')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .onClick(() => {
          router.pushUrl({ url: 'pages/PrivacyPolicyPage' })
        })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder MenuRow(label: string, value: string, hasDivider?: boolean) {
    Column() {
      Row() {
        Text(label).fontSize(15).fontColor('#1A1A1A')
        Blank()
        Text(value).fontSize(15).fontColor('#1A1A1A')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })

      if (hasDivider) {
        Divider().color('#F5F5F5').strokeWidth(0.5).margin({ left: 16 })
      }
    }
    .width('100%')
  }

  @Builder UpdateLogRow(date: string, version: string, content: string) {
    Row() {
      Column() {
        Text(version)
          .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1A73E8')
        Text(date)
          .fontSize(11).fontColor('#1A1A1A').margin({ top: 2 })
      }
      .width(64)
      .alignItems(HorizontalAlign.Start)

      Text(content)
        .fontSize(13).fontColor('#1A1A1A')
        .layoutWeight(1)
        .margin({ left: 12 })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }
}
