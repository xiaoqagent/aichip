import { AppConstants } from '../constants/AppConstants'
import { RdbHelper } from '../database/RdbHelper'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { router } from '@kit.ArkUI'

const TAG = 'AIChip'

@Component
export struct MinePage {
  @State dbVersion: number = 0
  @State chipCount: number = 0
  private context: Context = getContext()

  aboutToAppear() {
    this.loadStats()
  }

  async loadStats() {
    try {
      const store = await RdbHelper.getStore(this.context)
      const rs = await store.querySql('SELECT COALESCE(MAX(db_version), 1) as v, COUNT(*) as c FROM chips WHERE is_deleted = 0')
      if (rs.goToFirstRow()) {
        this.dbVersion = rs.getLong(rs.getColumnIndex('v'))
        this.chipCount = rs.getLong(rs.getColumnIndex('c'))
      }
      rs.close()
      hilog.info(0x0001, TAG, `Mine stats: v${this.dbVersion}, ${this.chipCount} chips`)
    } catch (e) {
      this.dbVersion = AppConstants.DB_VERSION
    }
  }

  build() {
    Column() {
      // 头部
      Column() {
        Image($r('app.media.app_icon'))
          .width(72).height(72).borderRadius(16).margin({ top: 40 })

        Text(AppConstants.APP_NAME)
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ top: 14 })
        Text(`v${AppConstants.APP_VERSION}`)
          .fontSize(14).fontColor('#999').margin({ top: 6 })
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
          .fontSize(13).fontColor('#999')
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 8 })

        Column() {
          this.UpdateLogRow('2026-06-21', 'v2', '初始建库：5款AI芯片数据（GPU/NPU/HBM）')
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
          Text('用户协议').fontSize(15).fontColor('#333')
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
          Text('隐私政策').fontSize(15).fontColor('#333')
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

      // 预留：用户注册入口
      Column() {
        Row() {
          Text('登录 / 注册').fontSize(15).fontColor('#CCC')
          Blank()
          Text('敬请期待').fontSize(13).fontColor('#DDD')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .margin({ top: 12 })
      .enabled(false)
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder MenuRow(label: string, value: string, hasDivider?: boolean) {
    Column() {
      Row() {
        Text(label).fontSize(15).fontColor('#333')
        Blank()
        Text(value).fontSize(15).fontColor('#999')
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
          .fontSize(11).fontColor('#BBB').margin({ top: 2 })
      }
      .width(64)
      .alignItems(HorizontalAlign.Start)

      Text(content)
        .fontSize(13).fontColor('#666')
        .layoutWeight(1)
        .margin({ left: 12 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }
}
