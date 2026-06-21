import { ChipModel } from '../model/ChipModel'

@Reusable
@Component
export struct ChipCard {
  @Prop chip: ChipModel = {
    id: 0, name: '', model: '', manufacturer_id: 0, category_id: 0,
    architecture: '', process_node: '', release_date: '',
    key_specs_json: '{}', detail_specs_json: '[]', description: '',
    image_path: '', search_keywords: '', is_hot: 0, is_new: 0, is_deleted: 0,
    update_time: 0, db_version: 0
  }

  build() {
    Row() {
      // 左侧：芯片信息
      Column() {
        Row() {
          if (this.chip.is_hot === 1) {
            Text('热门')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF6B35')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ right: 6 })
          }
          if (this.chip.is_new === 1) {
            Text('新品')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor('#1A73E8')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          }
        }

        Text(this.chip.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .margin({ top: 4 })

        Text(this.chip.model)
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：箭头
      Image($r('sys.symbol.chevron_right'))
        .width(16)
        .height(16)
        .fillColor('#CCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }
}
