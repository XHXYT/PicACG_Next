import { keywords } from '../../api/comic';
import { LengthUnit, router } from '@kit.ArkUI';
import { RandomUtil } from '@pura/harmony-utils';
import { SettingsPage } from '../Settings';
import { PicState } from '../../entryability/AppState';


@ComponentV2
export default struct SearchHead {

  @Param @Require refreshKeyword: boolean
  @Local isShowSettings: boolean = false
  @Local showKey: string = ''

  aboutToAppear(): void {
    if (PicState.keywords.length === 0) {
      keywords().then(res => {
        PicState.keywords = res.keywords
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
    if (PicState.keywords.length !== 0) {
      this.showKey = PicState.keywords[RandomUtil.getRandomNumber(0, PicState.keywords.length)]
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
        PicState.pageStack.pushPath({ name: 'comic_search' })
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
          PicState.foregroundBlurMode = true
        })
        .bindSheet(this.isShowSettings!!, SettingsPage(), {
          height: 650,
          dragBar: false,
          backgroundColor: $r('app.color.start_window_background'),
          keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
          scrollSizeMode: ScrollSizeMode.CONTINUOUS,
          preferType: SheetType.CENTER,
          onWillDismiss: () => {
            // 开启背景模糊
            PicState.foregroundBlurMode = false
            // 打开设置
            this.isShowSettings = false
          },
          onWillSpringBackWhenDismiss: () => {}, // 预防错误回弹
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