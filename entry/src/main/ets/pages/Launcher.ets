import { router } from '@kit.ArkUI'
import { StorageKey } from '../common/Consts'
import { hilog } from '@kit.PerformanceAnalysisKit'

@Entry
@Component
struct Launcher {

  @State isLoading: boolean = false
  @StorageLink(StorageKey.TOKEN) token: string = ''

  aboutToAppear(): void {
    hilog.info(0x0000, 'PicaLauncher', '进入启动页%{public}s', )
    this.isLoading = true
    setTimeout(() => {
      animateTo({
        duration: 360,
        curve: Curve.ExtremeDeceleration,
        iterations: 1,
        playMode: PlayMode.Normal
      }, () => {
        this.isLoading = false
      })
    }, 2500)
    if ((this.token !== '')) {
      hilog.info(0x0000, 'PicaLauncher', '已登录%{public}s', )
      router.replaceUrl({ url: 'pages/Index' })
    } else {
      hilog.info(0x0000, 'PicaLauncher', '未登录%{public}s', )
      // router.replaceUrl({ url: 'pages/Login' })
    }
  }

  build() {
    Stack() {

      Column() {
        Image($rawfile('login_bg.png'))
          .height(this.isLoading ? '90%' : '80%')
          .objectFit(ImageFit.Contain)
          .aspectRatio(1)
          .margin({left: 12, right: 12})
        Button({ type: ButtonType.Capsule }) {
          Row() {
            Text('前往登录').fontColor(Color.White).textAlign(TextAlign.Center)
          }.height(40)
        }
        .width('20%')
        .backgroundColor($r('app.color.common_button_background_light'))
        .visibility(this.isLoading ? Visibility.None : Visibility.Visible)
        .clickEffect({ level: ClickEffectLevel.LIGHT })
        .onClick(() => {
          router.replaceUrl({ url: 'pages/Login' })
        })
      }.width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      LoadingProgress()
        .zIndex(1)
        .width(69)
        .enableLoading(this.isLoading)
        .color($r('app.color.common_button_background_light'))
        .visibility(this.isLoading ? Visibility.Visible : Visibility.None)

    }
  }

}