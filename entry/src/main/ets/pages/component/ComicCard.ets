import { ImageKnifeComponentV2 } from '@ohos/imageknifepro'
import { PreferenceManager } from '../../utils/preference/Settings';
import { ComicCardInterface } from '../../common/Model';
import { createLogger } from '../../utils/Logger';

const logger = createLogger('ComicCard')

@ComponentV2
export default struct ComicCard {

  @Param @Require comic: ComicCardInterface
  @Event onCardClick: (comic: ComicCardInterface) => void

  build() {
    Column() {
      Column() {
        ImageKnifeComponentV2({
          imageKnifeOption: {
            loadSrc: this.comic.image,
            placeholderSrc: $r('app.media.loading'),
            border: { radius: 6 },
          }
        })
          .height(160)
      }
      .borderRadius(6)
      .foregroundBlurStyle(PreferenceManager.privacy_mode ? BlurStyle.Thin : BlurStyle.NONE)

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
      logger.info(`点击了本子：${this.comic.id} - ${this.comic.title}`)
      this.onCardClick(this.comic)
    })
  }
}
