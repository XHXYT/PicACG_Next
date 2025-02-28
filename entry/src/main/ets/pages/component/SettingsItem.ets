@Component
export default struct SettingsItem {
  @Prop group: Array<SettingsItemAttribute[]>

  build() {
    Scroll(new Scroller()) {
      Column() {
        ForEach(this.group, (items: SettingsItemAttribute[]) => {
          Column() {
            ForEach(items, (item: SettingsItemAttribute, index) => {
              Row() {
                Text(item.name)
                  .padding({ left: 10 })
                  .width(item.type === 'Switch' ? '87%' : '90%')

                if (item.type === 'Switch') {
                  Toggle({ type: ToggleType.Switch, isOn: item.switchVal })
                    .selectedColor($r('app.color.common_button_background_light'))
                    .onChange(item.onChange)
                } else {
                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(25)
                    .align(Alignment.End)
                    .onClick(item.onClick)
                    .fontColor([$r('app.color.common_button_background_light')])

                }
              }
              .width('90%')
              .height(50)
              .borderRadius(20)
              .backgroundColor($r('app.color.listitem_background'))
              .visibility(item.show === false ? Visibility.None : Visibility.Visible)
              .onClick(item.onClick)

              Divider()
                .width('85%')
                .visibility(index >= items.length - 1 ? Visibility.None : Visibility.Visible)
            })
          }
          .borderRadius(20)
          .margin({ top: 15 })
          .backgroundColor($r('app.color.listitem_background'))
        })
      }.width('100%')
    }
    .width('100%')
    .scrollBar(BarState.Off)
  }
}

interface SettingsItemAttribute {
  name: string,
  type?: 'Normal' | 'Switch'
  onClick?: () => void
  switchVal?: boolean
  onChange?: (isOn: boolean) => void
  show?: boolean
}