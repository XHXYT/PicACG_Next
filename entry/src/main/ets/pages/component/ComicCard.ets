import { LogUtil } from '@pura/harmony-utils'
import { PreferenceStorageKey } from '../../utils/Preference'
import { ImageKnifeComponent } from '@ohos/imageknife'

@Component
export default struct ComicCard {
  @StorageProp(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @Consume('pageStack') pageStack: NavPathStack;
  @Prop comic: ComicCardInterface

  build() {
    Column() {
      Column() {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.comic.image,
            placeholderSrc: $r('app.media.loading'),
            border: { radius: 6 },
          }
        })
          .height(160)
      }
      .borderRadius(6)
      .foregroundBlurStyle(this.privacyMode ? BlurStyle.Thin : BlurStyle.NONE)

      Text(this.comic.title)
        .textAlign(TextAlign.Center)
        .margin({ top: 6 })
        .textOverflow({ overflow: TextOverflow.MARQUEE })
        .maxLines(1)
        .fontColor($r('app.color.custom_pink'))
        .fontWeight(500)
        .copyOption(CopyOptions.LocalDevice)
    }
    .width(150)
    .height(200)
    .padding(8)
    .borderRadius(10)
    .borderWidth(1)
    .borderColor($r('app.color.custom_gray'))
    .shadow({
      radius: 10,
      color: $r('app.color.custom_gray'),
      offsetX: 15,
      offsetY: 15
    })
    .onClick(() => {
      LogUtil.info(`点击了本子：${this.comic.id} - ${this.comic.title}`)
      this.pageStack.pushPathByName('ComicDetail', this.comic)
    })
  }
}

export interface ComicCardInterface {
  id: string
  image: string
  title: string
}