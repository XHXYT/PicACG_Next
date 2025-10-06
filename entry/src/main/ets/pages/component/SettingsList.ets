import { PreferenceItem } from "../../utils/Preference"
import { SymbolGlyphModifier } from "@kit.ArkUI"

@Component
export default struct SettingsList {

  @Prop group: Array<SettingsItemAttribute[]>
  @State currentItem?: SettingsItemAttribute = undefined
  @State menuSelected: string = ''
  @State menus: PreferenceItem[] = []
  @State isShowMenu: boolean = false

  build() {
    Column({ space: 10}) {
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
              }
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
              } else if (item.type === 'Menu') {
                Row({space: 5}) {
                  Text(item.tips)
                    .fontSize(15)
                    .fontColor($r('app.color.common_button_background_light'))
                  SymbolGlyph($r('sys.symbol.arrowtriangle_down_fill'))
                    .fontSize(14)
                    .fontColor([$r('app.color.common_button_background_light')])
                }
                .bindContextMenu(this.isShowMenu && this.currentItem?.name == item.name, this.MenuSetting(), {
                  onDisappear: () => {
                    this.isShowMenu = false
                  }
                })
              } else {
                Row() {
                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(25)
                    .fontColor([$r('app.color.common_button_background_light')])
                }.width(27)
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('100%')
            .borderRadius(20)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.currentItem = item
              console.log(`SettingsList 已点击 ${item.name}`)
              if (item.onClick) {
                item.onClick()
              }

              const itemName = item.name || '未知项目';
              // 检查 menus
              if (!item.menus) {
                console.warn(`[SettingsList] 项目 "${itemName}" 缺少 'menus' 属性，操作中止。`);
                return;
              }
              console.log(`[SettingsList] 项目 "${itemName}" item.menuValue: ${item.menuValue}`);
              // 检查 menuValue
              if (item.menuValue == null || item.menuValue == undefined) {
                console.warn(`[SettingsList] 项目 "${itemName}" 缺少 'menuValue' 属性，操作中止。`);
                return;
              }
              this.menuSelected = item.menuValue;
              this.menus = item.menus;
              console.log(`[SettingsList] 项目 "${itemName}" 菜单已准备完毕，当前 this.menuSelected：${this.menuSelected}`);
              if (this.isShowMenu) {
                return;
              }
              this.isShowMenu = true
            })
            .constraintSize({minHeight: 56})
            .padding({ left: 10, right: 9 })
          })
        }
        .borderRadius(20)
        .backgroundColor($r('app.color.listitem_background'))
      })
    }.width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MenuSetting() {
    Menu() {
      ForEach(this.menus, (menuItem: PreferenceItem, index: number) => {
        MenuItem({
          content: menuItem.name,
          symbolEndIcon: this.menuSelected == menuItem.value ? new SymbolGlyphModifier($r('sys.symbol.checkmark')) : undefined
        })
          .onChange(() => {
            if (this.menuSelected == menuItem.value) {
              return
            }
            this.menuSelected = menuItem.value
            if (this.currentItem && this.currentItem.onValueChange)
            this.currentItem.onValueChange(menuItem.key)
            this.isShowMenu = false
          })
      }, (item: PreferenceItem, index: number) => {
        return item.key
      })
    }
  }

}

export interface SettingsItemAttribute {
  image?: Resource
  name: string,
  subtitle?: string
  menus?: PreferenceItem[]
  tips?: string,
  type?: 'Normal' | 'Switch' | 'Tips' | 'Menu'
  onClick?: () => void
  menuValue?: string
  switchVal?: boolean
  onValueChange?: (value: number | string) => void
  onChange?: (isOn: boolean) => void
}