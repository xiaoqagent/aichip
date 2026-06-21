import { router } from '@kit.ArkUI'

@Entry
@Component
struct PrivacyPolicyPage {
  build() {
    Column() {
      Row() {
        Text('← 返回')
          .fontSize(14).fontColor('#1A73E8')
          .onClick(() => { router.back() })
        Text('隐私政策')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text('').width(48)
      }
      .width('100%').padding(16).backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          Text('AI芯片 APP 隐私政策')
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ top: 20, bottom: 16 })

          Text('更新日期：2026年6月21日')
            .fontSize(13).fontColor('#999').margin({ bottom: 24 })

          Text('一、信息收集')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('本应用为单机版工具，所有芯片数据存储在您的设备本地数据库中。我们不收集任何个人信息、不联网传输任何数据、不使用任何第三方统计或广告服务。')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 16 })

          Text('二、数据存储')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('芯片查询数据和搜索历史记录均存储于您的设备本地沙箱中（HarmonyOS 应用沙箱隔离），其他应用无法访问。您可以随时通过卸载应用清除所有数据。')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 16 })

          Text('三、权限说明')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('本应用不申请任何系统权限（无网络、无存储、无定位、无相机等权限）。')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 16 })

          Text('四、联系我们')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('如有任何隐私相关疑问，请联系：')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 8 })
          Text('邮箱：592499073@qq.com')
            .fontSize(14).fontColor('#1A73E8').lineHeight(22).margin({ bottom: 32 })
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
  }
}
