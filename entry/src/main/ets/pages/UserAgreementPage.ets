import { router } from '@kit.ArkUI'

@Entry
@Component
struct UserAgreementPage {
  build() {
    Column() {
      Row() {
        Text('← 返回')
          .fontSize(14).fontColor('#1A73E8')
          .onClick(() => { router.back() })
        Text('用户协议')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text('').width(48)
      }
      .width('100%').padding(16).backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          Text('AI芯片 APP 用户协议')
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ top: 20, bottom: 16 })

          Text('更新日期：2026年6月21日\n生效日期：2026年6月21日')
            .fontSize(13).fontColor('#999').margin({ bottom: 24 })

          Text('一、接受条款')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('欢迎使用"AI芯片"应用（以下简称"本应用"）。本应用由开发者个人开发并维护。您在使用本应用前，请仔细阅读本协议。如您不同意本协议任何条款，请勿安装或使用本应用。您安装、使用本应用的行为即视为您已阅读并同意接受本协议全部条款的约束。')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 16 })

          Text('二、服务说明')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('本应用是一款AI芯片信息查询与对比工具，主要功能包括：\n1. 芯片关键字搜索与参数查询\n2. 芯片分类浏览（GPU/NPU/CPU/HBM等）\n3. 芯片参数对比（后续版本开放）\n4. 集群信息查询（后续版本开放）\n\n本应用为单机版工具，所有数据存储在您的设备本地数据库，无需联网即可使用全部功能。')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 16 })

          Text('三、用户义务')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('您在使用本应用时应遵守中华人民共和国相关法律法规，不得利用本应用从事任何违法违规活动。本应用中的芯片参数数据仅供参考，不构成任何投资建议或技术选型依据。')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 16 })

          Text('四、知识产权')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('本应用的所有内容，包括但不限于程序代码、界面设计、数据结构，其知识产权归开发者所有。芯片参数数据来源于各厂商公开发布的产品资料，其知识产权归各厂商所有。')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 16 })

          Text('五、免责声明')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('本应用提供的芯片参数信息均来源于公开渠道，开发者已尽力确保数据准确性，但不保证数据的完整性、及时性和无误性。因使用本应用数据产生的任何直接或间接损失，开发者不承担任何责任。芯片参数以各厂商官网发布的最新数据为准。')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 16 })

          Text('六、协议变更')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('开发者保留随时修改本协议的权利。修改后的协议将在应用更新时一并发布。如您继续使用本应用，视为您同意修改后的协议。')
            .fontSize(14).fontColor('#555').lineHeight(22).margin({ bottom: 16 })

          Text('七、联系我们')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ bottom: 8 })
          Text('如有任何疑问或建议，请联系：')
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
