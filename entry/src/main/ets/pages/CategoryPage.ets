import { CategoryModel } from '../model/CategoryModel'

@Component
export struct CategoryPage {
  @State categories: CategoryModel[] = []

  build() {
    Column() {
      Text('芯片分类')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      Grid() {
        ForEach(this.categories, (cat: CategoryModel) => {
          GridItem() {
            Column() {
              Text(cat.name)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A73E8')

              Text(cat.description)
                .fontSize(12)
                .fontColor('#999')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .padding({ left: 16, right: 16 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }
}
