// Tab 容器（5个页签）
import { SearchPage } from './SearchPage'
import { CategoryPage } from './CategoryPage'
import { ComparePage } from './ComparePage'
import { ClusterPage } from './ClusterPage'
import { MinePage } from './MinePage'

interface TabItem {
  title: string
  icon: Resource
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  private tabItems: TabItem[] = [
    { title: '查询', icon: $r('app.media.app_icon') },
    { title: '分类', icon: $r('app.media.app_icon') },
    { title: '对比', icon: $r('app.media.app_icon') },
    { title: '集群', icon: $r('app.media.app_icon') },
    { title: '我的', icon: $r('app.media.app_icon') }
  ]

  @Builder TabContent(index: number) {
    if (index === 0) {
      SearchPage()
    } else if (index === 1) {
      CategoryPage()
    } else if (index === 2) {
      ComparePage()
    } else if (index === 3) {
      ClusterPage()
    } else {
      MinePage()
    }
  }

  build() {
    Tabs({
      barPosition: BarPosition.End,
      index: this.currentIndex
    }) {
      ForEach(this.tabItems, (tab: TabItem, index: number) => {
        TabContent() {
          this.TabContent(index)
        }
        .tabBar(this.TabBarBuilder(tab.title, tab.icon, index))
      })
    }
    .onChange((index: number) => {
      this.currentIndex = index
    })
    .width('100%')
    .height('100%')
    .barHeight(56)
    .backgroundColor('#F5F6FA')
  }

  @Builder TabBarBuilder(title: string, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(index === this.currentIndex ? '#1A73E8' : '#999')
      Text(title)
        .fontSize(11)
        .fontColor(index === this.currentIndex ? '#1A73E8' : '#999')
        .margin({ top: 2 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 4 })
  }
}
