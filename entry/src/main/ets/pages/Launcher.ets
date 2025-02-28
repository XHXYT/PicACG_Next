import { router } from '@kit.ArkUI'
import { StorageKey } from '../common/Consts'

@Entry
@Component
struct Launcher {

  aboutToAppear(): void {
    if ((AppStorage.get(StorageKey.TOKEN) !== '')) {
      router.replaceUrl({ url: 'pages/Index' })
    } else {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }

  build() {
    Column() {
      Image($r('app.media.login_bg'))
        .objectFit(ImageFit.Contain)
        .aspectRatio(1)
        .margin({left: 12, right: 12})
    }.width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

}