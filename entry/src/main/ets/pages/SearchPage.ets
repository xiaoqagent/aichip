import { SearchBar } from '../components/SearchBar'
import { ChipCard } from '../components/ChipCard'
import { ChipModel } from '../model/ChipModel'

@Component
export struct SearchPage {
  @State searchText: string = ''
  @State results: ChipModel[] = []
  @State isSearching: boolean = false

  build() {
    Column() {
      SearchBar({ value: $searchText })

      if (this.isSearching) {
        LoadingProgress()
          .width(24)
          .height(24)
          .margin({ top: 40 })
      } else if (this.searchText.length === 0) {
        Text('输入芯片名称或型号搜索')
          .fontSize(15)
          .fontColor('#BFBFBF')
          .margin({ top: 60 })
      } else if (this.results.length === 0) {
        Text('未找到匹配的芯片')
          .fontSize(15)
          .fontColor('#BFBFBF')
          .margin({ top: 40 })
      } else {
        List() {
          ForEach(this.results, (chip: ChipModel, index: number) => {
            ListItem() {
              ChipCard({ chip: chip })
                .margin({ left: 16, right: 16, top: 4, bottom: 4 })
            }
          }, (chip: ChipModel) => `${chip.id}_${chip.update_time}`)
        }
        .layoutWeight(1)
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }
}
