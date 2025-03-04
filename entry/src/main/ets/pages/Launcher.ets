import { router } from '@kit.ArkUI'
import { StorageKey } from '../common/Consts'
import { hilog } from '@kit.PerformanceAnalysisKit'

@Entry
@Component
struct Launcher {

  @State isLoading: boolean = false

  aboutToAppear(): void {
    hilog.info(0x0000, 'PicaLauncher', '进入启动页%{public}s', )
    setTimeout(() => {
      this.isLoading = true
      setTimeout(() => {this.isLoading = false}, 9000)
      if ((AppStorage.get(StorageKey.TOKEN) !== '')) {
        hilog.info(0x0000, 'PicaLauncher', '已登录%{public}s', )
        router.replaceUrl({ url: 'pages/Index' })
      } else {
        hilog.info(0x0000, 'PicaLauncher', '未登录%{public}s', )
        router.replaceUrl({ url: 'pages/Login' })
      }
    }, 1000)
  }

  build() {
    Column() {
      Image($rawfile('login_bg.png'))
        .objectFit(ImageFit.Contain)
        .aspectRatio(1)
        .margin({left: 12, right: 12})
      LoadingProgress()
        .color($r('app.color.common_button_background_light'))
        .enableLoading(this.isLoading)
      if (!this.isLoading) {
        Button({ type: ButtonType.Capsule }) {
          Row() {
            Text('去登录').fontColor(Color.White).textAlign(TextAlign.Center)
          }.height(40)
        }
        .width('20%')
        .backgroundColor($r('app.color.common_button_background_light'))
        .clickEffect({ level: ClickEffectLevel.LIGHT })
        .onClick(() => {
          router.replaceUrl({ url: 'pages/Login' })
        })
      }
    }.width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

}