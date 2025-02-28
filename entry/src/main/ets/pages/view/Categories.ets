import { ImageKnifeComponent } from '@ohos/imageknife'
import { LogUtil } from '@pura/harmony-utils'
import { categories } from '../../api/comic'
import { Category } from '../../api/models'
import { CategoryFilter, LocalCategories, LocalCategory } from '../../common/Config'
import { StorageKey } from '../../common/Consts'
import { PreferenceStorageKey } from '../../utils/Preference'
import { SearchType } from './Comics'

/**
 * 分类目录
 */
@Component
export default struct Categories {
  @StorageProp(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
  @StorageLink(StorageKey.CATEGORY) category: string[] = []
  @Consume('pageStack') pageStack: NavPathStack;
  @State remoteCategories: Category[] = []
  @State localCategories: LocalCategory[] = LocalCategories

  aboutToAppear(): void {
    categories().then(res => {
      animateTo({ duration: 300 }, () => {
        this.remoteCategories = res.categories.filter((item) =>!CategoryFilter.includes(item.title))
      })
      const cate: string[] = []
      this.remoteCategories.forEach(item => {
        if (item._id) {
          cate.push(item.title)
        }
      })
      this.category = cate
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
            this.CategoryCard(`${this.imageApi}${item.thumb.path}`, item.title, 'Comics',
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
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: img,
            placeholderSrc: $r('app.media.loading'),
            border: { radius: 6 },
          }
        })
          .height(115)
      }
      .borderRadius(6)
      .foregroundBlurStyle(this.privacyMode ? BlurStyle.Thin : BlurStyle.NONE)

      Text(title)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .fontColor($r('app.color.custom_pink'))
        .fontWeight(500)
    }
    .onClick(() => {
      LogUtil.info('跳转路由：', router)
      this.pageStack.pushPath({
        name: router,
        param
      })
    })
  }
}