import { ImageKnifeComponent, ImageKnifeComponentV2 } from '@ohos/imageknifepro'
import { LogUtil } from '@pura/harmony-utils'
import { categories } from '../../api/comic'
import { Category } from '../../api/models'
import { CategoryFilter, LocalCategories, LocalCategory } from '../../common/Config'
import { PicState } from '../../entryability/AppState'
import { PreferenceManager } from '../../utils/preference/Settings'
import { SearchType } from '../../common/Model'
import { ToastUtil } from '../../utils/ToastUtils'


/**
 * 分类目录
 */
@ComponentV2
export default struct Categories {

  @Local remoteCategories: Category[] = []
  @Local localCategories: LocalCategory[] = LocalCategories

  aboutToAppear(): void {
    categories().then(res => {
      ToastUtil.animateTo({ duration: 300 }, () => {
        this.remoteCategories = res.categories.filter((item) =>!CategoryFilter.includes(item.title))
      })
      const cate: string[] = []
      this.remoteCategories.forEach(item => {
        if (item._id) {
          cate.push(item.title)
        }
      })
      PicState.category = cate
    }).catch((err: Error) => {
      LogUtil.error(`错误: ${err.message}`)
      LogUtil.error(err.stack)
    })
  }

  build() {
    Column() {
      List({ space: 20, initialIndex: 0 }) {
        // 本地分类
        ForEach(this.localCategories, (item: LocalCategory) => {
          ListItem({ style: ListItemStyle.CARD }) {
            this.CategoryCard(item.img, item.title, item.router, item.param)
          }
          .width(115)
          .height(145)
          .border({ width: 1, color: $r('app.color.custom_gray') })
          .shadow({
            radius: 10,
            color: $r('app.color.custom_gray'),
            offsetX: 10,
            offsetY: 10
          })
        })
        // 远程分类
        ForEach(this.remoteCategories, (item: Category) => {
          ListItem({ style: ListItemStyle.CARD }) {
            this.CategoryCard(`${PreferenceManager.image_api}${item.thumb.path}`, item.title, 'comics',
              { type: SearchType.Category, key: item.title })
          }
          .width(115)
          .height(145)
          .transition(TransitionEffect.move(TransitionEdge.BOTTOM))
          .border({ width: 1, color: $r('app.color.custom_gray') })
          .shadow({
            radius: 10,
            color: $r('app.color.custom_gray'),
            offsetX: 10,
            offsetY: 10
          })
        })
      }
      .height('100%')
      .width('100%')
      .lanes(3)
      .scrollBar(BarState.Off)
    }.backgroundColor($r('app.color.start_window_background'))
    .height('100%')
    .width('100%')
    .padding(10)
  }

  @Builder
  CategoryCard(img: ResourceStr, title: string, router?: string, param?: ESObject) {
    Column() {
      Column() {
        ImageKnifeComponentV2({
          imageKnifeOption: {
            loadSrc: img,
            placeholderSrc: $r('app.media.loading'),
            border: { radius: 6 },
          }
        })
          .height(115)
      }
      .borderRadius(6)
      .foregroundBlurStyle(PreferenceManager.privacy_mode ? BlurStyle.Thin : BlurStyle.NONE)

      Text(title)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .fontColor($r('app.color.custom_pink'))
        .fontWeight(500)
    }
    .onClick(() => {
      PicState.pageStack.pushPath({
        name: router,
        param
      })
    })
  }

}