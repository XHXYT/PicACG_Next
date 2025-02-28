import { ImageKnifeComponent, ImageKnifeOption } from '@ohos/imageknife';
import { LogUtil } from '@pura/harmony-utils';
import { StorageKey } from '../../common/Consts';
import { PreferenceStorageKey } from '../../utils/Preference';
import { ComicCardInterface } from './ComicCard';

@Component
export default struct ComicListItem {
  @StorageProp(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @StorageProp(StorageKey.FILTER_CATEGORY) filterCategory: string[] = []
  @Consume('pageStack') pageStack: NavPathStack;
  @Prop image: string
  @Prop _id: string
  @Prop title: string = '无标题'
  @Prop pagesCount: number = 0
  @Prop finished: boolean = false
  @Prop author: string = ''
  @Prop categories: string[] = []
  @Prop likesCount: number = 0
  @Prop viewCount: number = 0
  @Prop epsCount: number = 0
  @Prop filter: boolean = false

  build() {
    Row() {
      Column() {
        ImageKnifeComponent({
          imageKnifeOption:
          {
            loadSrc: this.image,
            placeholderSrc: $r('app.media.loading'),
            border: {radius:10}
          }
        })
          .width(100)
      }
      .height(160)
      .borderRadius(10)
      .margin({ right: 16, top: 10, bottom: 10 })
      .foregroundBlurStyle(this.privacyMode ? BlurStyle.Thin : BlurStyle.NONE)

      Column() {
        Row() {
          Text(`${this.title}${this.pagesCount ? `（${this.pagesCount}P）` : ''}${this.finished ? '（完）' : ''}`)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        Row() {
          Text(`作者：${this.author}`)
            .fontColor($r('app.color.custom_pink'))
            .width('100%')
        }
        .margin({ top: 5 })

        Row() {
          Text(`分类：${this.categories.join(',')}`)
            .fontColor(Color.Gray)
            .width('100%')
        }
        .margin({ top: 5 })

        Row() {
          Row() {
            Image($r('app.media.ic_public_heart'))
              .width(14)
              .fillColor($r('app.color.custom_pink'))
            Text(`${this.likesCount}`)
              .fontColor(Color.Gray)
              .fontSize(14)
              .margin({ left: 5 })
          }

          Row() {
            Image($r('app.media.ic_public_eye'))
              .width(14)
              .fillColor($r('app.color.custom_pink'))
            Text(`${this.viewCount}`)
              .fontColor(Color.Gray)
              .fontSize(14)
              .margin({ left: 5 })
          }
          .margin({ left: 15 })
          .visibility(this.viewCount ? Visibility.Visible : Visibility.None)

          Row() {
            Image($r('app.media.ic_public_book'))
              .width(14)
              .fillColor($r('app.color.custom_pink'))
            Text(`${this.epsCount}`)
              .fontColor(Color.Gray)
              .fontSize(14)
              .margin({ left: 5 })
          }
          .margin({ left: 15 })
          .visibility(this.epsCount ? Visibility.Visible : Visibility.None)
        }
        .width('100%')
        .margin({ top: 5 })
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .padding({ top: 20, bottom: 20 })
    }
    .width('100%')
    .height(180)
    .layoutWeight(1)
    .overlay(this.filter && this.isFilter(this.categories) ? this.filterOverlay(this.categories) : undefined)
    .onClick(() => {
      if (this.filter && this.isFilter(this.categories)) {
        return
      }
      LogUtil.info(`点击了本子：${this._id} - ${this.title}`)
      let comic: ComicCardInterface = {
        id: this._id,
        image: this.image,
        title: this.title
      }
      this.pageStack.pushPathByName('ComicDetail', comic)
    })
  }

  @Builder
  filterOverlay(comicCategory: string[]) {
    Stack() {
      Row()
        .width('100%')
        .height(180)
        .foregroundBlurStyle(BlurStyle.Thin)

      Text(`根据标签屏蔽：${comicCategory.filter(c => this.filterCategory.indexOf(c) >= 0).join('、')}`)
        .width('100%')
        .height(20)
        .borderRadius(10)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.common_button_background_weight'))
        .fontColor(Color.White)
        .margin({ top: 80 })
    }
    .width('100%')
    .height(180)
  }

  isFilter(comicCategory: string[]): boolean {
    for (let cc of comicCategory) {
      for (let fc of this.filterCategory) {
        if (cc === fc) {
          return true
        }
      }
    }
    return false
  }
}