import { SearchBar } from '../components/SearchBar'
import { ChipCard } from '../components/ChipCard'
import { ChipModel } from '../model/ChipModel'
import { ChipDao } from '../dao/ChipDao'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { router } from '@kit.ArkUI'
import { preferences } from '@kit.ArkData'

const TAG = 'AIChip'
const HISTORY_KEY = 'search_history'
const HISTORY_MAX = 10

@Component
export struct SearchPage {
  @State searchText: string = ''
  @State results: ChipModel[] = []
  @State isLoading: boolean = false
  @State showHistory: boolean = true
  @State historyList: string[] = []
  private timerId: number = -1
  private searchCallCount: number = 0
  private context: Context = getContext()

  aboutToAppear() {
    this.loadHistory()
  }

  async loadHistory() {
    try {
      const prefs = await preferences.getPreferences(this.context, 'AIChipPrefs')
      const raw: string = await prefs.get(HISTORY_KEY, '[]') as string
      this.historyList = JSON.parse(raw) as string[]
    } catch (e) {
      this.historyList = []
    }
  }

  async saveHistory(keyword: string) {
    if (!keyword || keyword.length === 0) return
    // 去重 + 移到最后
    const idx = this.historyList.indexOf(keyword)
    if (idx >= 0) this.historyList.splice(idx, 1)
    this.historyList.push(keyword)
    // 截断
    if (this.historyList.length > HISTORY_MAX) {
      this.historyList = this.historyList.slice(-HISTORY_MAX)
    }
    try {
      const prefs = await preferences.getPreferences(this.context, 'AIChipPrefs')
      await prefs.put(HISTORY_KEY, JSON.stringify(this.historyList))
      await prefs.flush()
    } catch (e) {
      // ignore
    }
  }

  async doSearch(keyword: string) {
    this.searchCallCount++
    hilog.info(0x0001, TAG, `Search called #${this.searchCallCount}: "${keyword}"`)

    if (keyword.length === 0) {
      this.results = []
      this.showHistory = true
      return
    }
    this.showHistory = false
    this.isLoading = true

    try {
      this.results = await ChipDao.searchChips(this.context, keyword)
      hilog.info(0x0001, TAG, `Search results: ${this.results.length}`)
    } catch (e) {
      hilog.error(0x0001, TAG, `Search failed: ${JSON.stringify(e)}`)
      this.results = []
    } finally {
      this.isLoading = false
    }
  }

  onTextChange(text: string) {
    this.searchText = text
    clearTimeout(this.timerId)
    if (text.length === 0) {
      this.results = []
      this.showHistory = true
      return
    }
    this.timerId = setTimeout(async () => {
      await this.doSearch(text)
      await this.saveHistory(text)
    }, 300)
  }

  onHistoryTap(keyword: string) {
    this.searchText = keyword
    this.showHistory = false
    this.doSearch(keyword)
  }

  onChipClick(chip: ChipModel) {
    hilog.info(0x0001, TAG, `Router to detail: chipId=${chip.id}`)
    router.pushUrl({
      url: 'pages/ChipDetailPage',
      params: { chipId: chip.id, chipName: chip.name }
    })
  }

  build() {
    Column() {
      SearchBar({ value: $searchText, onChange: this.onTextChange.bind(this) })

      if (this.searchText.length === 0 && this.showHistory && this.historyList.length > 0) {
        // 搜索历史
        List() {
          ForEach(this.historyList.reverse(), (keyword: string) => {
            ListItem() {
              Row() {
                Image($r('sys.symbol.magnifyingglass'))
                  .width(16).height(16).fillColor('#999')
                Text(keyword)
                  .fontSize(14).fontColor('#666').margin({ left: 8 }).layoutWeight(1)
                Image($r('sys.symbol.xmark'))
                  .width(14).height(14).fillColor('#CCC')
                  .onClick(() => {
                    const i = this.historyList.indexOf(keyword)
                    if (i >= 0) this.historyList.splice(i, 1)
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
              .onClick(() => { this.onHistoryTap(keyword) })
            }
          })
        }
        .layoutWeight(1)
      }

      if (this.isLoading) {
        LoadingProgress()
          .width(24).height(24)
          .margin({ top: 40 })
      } else if (this.searchText.length > 0 && this.results.length === 0) {
        // 空状态
        Column() {
          Image($r('app.media.app_icon'))
            .width(80).height(80).opacity(0.3)
          Text('未找到匹配的芯片')
            .fontSize(15).fontColor('#BFBFBF').margin({ top: 16 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.results.length > 0) {
        List() {
          ForEach(this.results, (chip: ChipModel, index: number) => {
            ListItem() {
              ChipCard({ chip: chip })
                .margin({ left: 16, right: 16, top: 4, bottom: 4 })
                .onClick(() => { this.onChipClick(chip) })
            }
          }, (chip: ChipModel) => `${chip.id}_${chip.update_time}`)
        }
        .layoutWeight(1).margin({ top: 8 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F6FA')
  }
}
