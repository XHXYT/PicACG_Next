import { router } from '@kit.ArkUI'
import { StorageKey } from '../common/Consts'
import { hilog } from '@kit.PerformanceAnalysisKit'

@Entry
@Component
struct Launcher {

  aboutToAppear(): void {
    hilog.info(0x0000, 'PicaLauncher', '进入启动页%{public}s', )
    if ((AppStorage.get(StorageKey.TOKEN) !== '')) {
      hilog.info(0x0000, 'PicaLauncher', '已登录%{public}s', )
      router.replaceUrl({ url: 'pages/Index' })
    } else {
      hilog.info(0x0000, 'PicaLauncher', '未登录%{public}s', )
      router.replaceUrl({ url: 'pages/Login' })
    }
  }

  build() {
    Column() {
      Image($rawfile('login_bg.png'))
        .objectFit(ImageFit.Contain)
        .aspectRatio(1)
        .margin({left: 12, right: 12})
    }.width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

}