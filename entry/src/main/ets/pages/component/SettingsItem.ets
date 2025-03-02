@Component
export default struct SettingsItem {
  @Prop group: Array<SettingsItemAttribute[]>

  build() {
    Column({space: 12}) {
      ForEach(this.group, (items: SettingsItemAttribute[]) => {
        Column() {
          ForEach(items, (item: SettingsItemAttribute, index) => {
            Row({space: 10}) {
              if (item.image) {
                Image(item.image)
                  .width(48)
                  .height(48)
                  .borderRadius(100)
              }
              // 标题
              Column({space: 2}) {
                Text(item.name)
                  .fontWeight(FontWeight.Medium)
                  .fontSize(16)
                if(item.subtitle) {
                  Text(item.subtitle)
                    .fontWeight(FontWeight.Normal)
                    .fontColor($r('app.color.common_button_background_light'))
                    .fontSize(14)
                }
              }.layoutWeight(1)
              .constraintSize({minHeight: 49})
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Start)
              Blank()
              if (item.type === 'Switch') {
                Toggle({ type: ToggleType.Switch, isOn: item.switchVal })
                  .selectedColor($r('app.color.common_button_background_light'))
                  .onChange(item.onChange)
              } else if (item.type === 'Tips') {
                Text(item.tips)
                  .fontSize(15)
                  .fontColor($r('app.color.common_button_background_light'))
              } else  {
                Row() {
                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(25)
                    .fontColor([$r('app.color.common_button_background_light')])
                }.width(27)
              }
            }
            .width('90%')
            .borderRadius(20)
            .onClick(item.onClick)
            .constraintSize({minHeight: 56})
            .backgroundColor($r('app.color.listitem_background'))
            .padding({left: 10, right: 12, top: 5, bottom: 5})
            .visibility(item.show === false ? Visibility.None : Visibility.Visible)

            Divider()
              .width('85%')
              .visibility(index >= items.length - 1 ? Visibility.None : Visibility.Visible)
          })
        }
        .borderRadius(20)
        .backgroundColor($r('app.color.listitem_background'))
      })
    }.width('100%')
  }
}

interface SettingsItemAttribute {
  image?: Resource
  name: string,
  subtitle?: string
  tips?: string,
  type?: 'Normal' | 'Switch' | 'Tips'
  onClick?: () => void
  switchVal?: boolean
  onChange?: (isOn: boolean) => void
  show?: boolean
}