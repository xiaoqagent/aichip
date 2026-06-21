@Component
export struct SearchBar {
  @Link value: string
  @Prop placeholder: string = '搜索芯片名称或型号'
  onChange?: (text: string) => void

  build() {
    Row() {
      Image($r('sys.symbol.magnifyingglass'))
        .width(18)
        .height(18)
        .fillColor('#999')
        .margin({ left: 12 })

      TextInput({ text: this.value, placeholder: this.placeholder })
        .fontSize(15)
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .height(44)
        .borderRadius(0)
        .onChange((text: string) => {
          this.value = text
          if (this.onChange) {
            this.onChange(text)
          }
        })
    }
    .width('100%')
    .height(44)
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .shadow({
      radius: 4,
      color: '#10000000',
      offsetX: 0,
      offsetY: 2
    })
    .margin({ left: 16, right: 16, top: 12, bottom: 8 })
  }
}
