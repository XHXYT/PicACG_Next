import { ImageKnifeComponentV2, ImageKnifeOption } from '@ohos/imageknifepro';
import { ComicCardInterface } from '../../common/Model';
import { PicState } from '../../entryability/AppState';
import { createLogger } from '../../utils/Logger';
import { PreferenceManager } from '../../utils/preference/Settings';

const logger = createLogger('ComicListItem')


@ComponentV2
export default struct ComicListItem {

  @Param image: string = '';
  @Param _id: string = '';
  @Param title: string = '无标题';
  @Param pagesCount: number = 0;
  @Param finished: boolean = false;
  @Param author: string = '';
  @Param categories: string[] = [];
  @Param likesCount: number = 0;
  @Param viewCount: number = 0;
  @Param epsCount: number = 0;
  @Param filter: boolean = false;

  @Event onItemClick: (comic: ComicCardInterface) => void = () => {};

  build() {
    Row() {
      Column() {
        ImageKnifeComponentV2({
          imageKnifeOption: {
            loadSrc: this.image,
            placeholderSrc: $r('app.media.loading'),
            border: { radius: 10 }
          }
        })
          .width(100)
      }
      .height(160)
      .borderRadius(10)
      .margin({ right: 16, top: 10, bottom: 10 })
      .foregroundBlurStyle(PreferenceManager.privacy_mode ? BlurStyle.Thin : BlurStyle.NONE)

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
      // 如果触发了屏蔽，不响应点击
      if (this.filter && this.isFilter(this.categories)) {
        return;
      }
      logger.info(`点击了本子：${this._id} - ${this.title}`);
      // 组装数据并触发事件，由父组件决定路由跳转逻辑
      let comic: ComicCardInterface = {
        id: this._id,
        image: this.image,
        title: this.title
      };
      this.onItemClick(comic);
    })
  }

  @Builder
  filterOverlay(comicCategory: string[]) {
    Stack() {
      Row()
        .width('100%')
        .height(180)
        .foregroundBlurStyle(BlurStyle.Thin)
      Text(`根据标签屏蔽：${comicCategory.filter(c => PicState.filterCategory.indexOf(c) >= 0).join('、')}`)
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

  // 判断逻辑
  private isFilter(comicCategory: string[]): boolean {
    return comicCategory.some(c => PicState.filterCategory.includes(c));
  }

}
