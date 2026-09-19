import { ImageKnifeComponentV2, ImageInfo } from '@ohos/imageknifepro'
import { Logger } from '../../utils/Logger'
import { PreferenceManager } from '../../utils/preference/Settings'

/**
 * 用户头像组件
 * 无头像（或未加载）时显示粉色圆底 + 昵称首字符占位；隐私模式下模糊显示
 */
@ComponentV2
export struct UserAvatar {
  /** 头像地址，空串时显示首字符占位 */
  @Param avatarUrl: string = ''
  /** 无头像时取首字符的展示名 */
  @Param displayName: string = ''
  /** 头像直径 vp */
  @Param avatarSize: number = 48

  build() {
    if (this.avatarUrl !== '') {
      ImageKnifeComponentV2({
        imageKnifeOption: {
          loadSrc: this.avatarUrl,
          placeholderSrc: $r('sys.media.ic_eraser_big'),
          objectFit: ImageFit.Cover,
          border: { radius: this.avatarSize / 2 },
          onLoadListener: {
            onLoadStart: (imageInfo: ImageInfo) => {
              Logger.getInstance().debug('UserAvatar', `加载开始：`, JSON.stringify(imageInfo))
            },
            onLoadFailed: (err: string, imageInfo: ImageInfo) => {
              Logger.getInstance().debug('UserAvatar', `加载失败：${err}, Data: `, JSON.stringify(imageInfo))
            },
            onLoadSuccess: (imageInfo: ImageInfo) => {
              Logger.getInstance().debug('UserAvatar', `加载完成：`, JSON.stringify(imageInfo))
            }
          }
        }
      })
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(100)
        .clip(true)
        .foregroundBlurStyle(PreferenceManager.privacy_mode ? BlurStyle.Thin : BlurStyle.NONE)
    } else {
      Text(this.displayName.length > 0 ? this.displayName.substring(0, 1) : '?')
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .backgroundColor($r('app.color.common_button_background_light'))
        .fontColor(Color.White)
        .fontSize(this.avatarSize * 0.42)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
    }
  }
}
