import { keywords } from '../../api/comic';
import { StorageKey } from '../../common/Consts';
import { LengthUnit, router } from '@kit.ArkUI';
import { RandomUtil } from '@pura/harmony-utils';
import { SettingsPage } from '../Settings';

@Component
export default struct SearchHead {
  // 背景模糊
  @StorageLink('foregroundBlur') foregroundBlurMode: boolean = false
  @StorageLink(StorageKey.KEYWORDS) keywords: string[] = []
  @Link @Watch('onRefreshKeyword') refreshKeyword: boolean
  @Consume('pageStack') pageStack: NavPathStack;
  @State isShowSettings: boolean = false
  @State showKey: string = ''

  aboutToAppear(): void {
    if (this.keywords.length === 0) {
      keywords().then(res => {
        this.keywords = res.keywords
        this.changeShowKey()
      })
    } else {
      this.changeShowKey()
    }
  }

  onRefreshKeyword() {
    this.changeShowKey()
  }

  changeShowKey() {
    if (this.keywords.length !== 0) {
      this.showKey = this.keywords[RandomUtil.getRandomNumber(0, this.keywords.length)]
    }
  }

  build() {
    Row() {
      Row() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontColor([Color.Gray])
          .fontSize(21)
        Text(this.showKey)
          .margin({ left: 10 })
          .fontSize(16)
          .fontColor(Color.Gray)
      }
      .height(30)
      .padding(5)
      .margin({
        top: 5,
        bottom: 5,
        left: 10,
      })
      .borderWidth(1)
      .layoutWeight(1)
      .borderRadius(50)
      .borderColor($r('app.color.custom_gray'))
      .onClick(() => {
        this.pageStack.pushPath({ name: 'ComicSearch' })
      })

      Row() {
        Button() {
          SymbolGlyph($r('sys.symbol.gearshape_fill'))
            .fontSize(24)
            .fontColor([$r('app.color.common_button_background_light')])
        }
        .width(30)
        .height(30)
        .stateEffect(false)
        .type(ButtonType.Circle)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.8 })
        .onClick(() => {
          this.isShowSettings = true
          this.foregroundBlurMode = true
        })
        .bindSheet($$this.isShowSettings, SettingsPage(), {
          detents: [SheetSize.LARGE],
          dragBar: false,
          backgroundColor: $r('app.color.start_window_background'),
          keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
          scrollSizeMode: ScrollSizeMode.CONTINUOUS,
          preferType: SheetType.CENTER,
          onWillDismiss: () => {
            // 开启背景模糊
            this.foregroundBlurMode = false
            // 打开设置
            this.isShowSettings = false
          },
          onWillSpringBackWhenDismiss: () => {},
          onDisappear: () => {}
        })
      }.height(30).width(40)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.start_window_background'))
    .borderWidth({
      start: { value: 0, unit: LengthUnit.VP },
      end: { value: 0, unit: LengthUnit.VP },
      top: { value: 0, unit: LengthUnit.VP },
      bottom: { value: 1, unit: LengthUnit.VP },
    })
    .borderColor($r('app.color.custom_gray'))
  }
}