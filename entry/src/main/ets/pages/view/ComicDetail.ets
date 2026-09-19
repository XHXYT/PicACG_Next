import { ImageKnifeComponent } from '@ohos/imageknifepro'
import { DateUtil } from '@pura/harmony-utils'
import { ComicEp } from '../../api/models'
import { TitleBar, TitleTextPosition } from '../component/TitleBar'
import { Chip, ChipSize, LengthUnit } from '@kit.ArkUI'
import ComicCardScroll from '../component/ComicCardScroll'
import CommentList from '../component/CommentList'
import { PreferenceManager } from '../../utils/preference/Settings'
import { buildImageUrl } from '../../common/Consts'
import { ComicCardInterface, SearchType } from '../../common/Model'
import { PicState } from '../../entryability/AppState'
import { ComicDetailVM } from '../../viewmodel/ComicDetailVM'


@Builder
export function ComicDetailBuilder(name: string, param: Object) {
  ComicDetail()
}


@ComponentV2
export default struct ComicDetail {

  @Local vm: ComicDetailVM = new ComicDetailVM()

  build() {
    NavDestination() {
      TitleBar({
        title: this.vm.comic?.title,
        titlePosition: TitleTextPosition.LEFT
      })
      Scroll(new Scroller()) {
        Column() {
          // 顶部基本信息
          Row() {
            Column() {
              ImageKnifeComponent({
                imageKnifeOption: {
                  loadSrc: this.vm.comic?.image,
                  placeholderSrc: $r('app.media.loading'),
                  objectFit: ImageFit.Cover,
                  border: { radius: 6 },
                }
              })
                .width(86)
                .height(120)
            }
            .margin({ right: 15 })
            .borderRadius(6)
            .foregroundBlurStyle(PreferenceManager.privacy_mode ? BlurStyle.Thin : BlurStyle.NONE)

            Column() {
              Row() {
                Text(`${this.vm.comic?.title}`)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }

              Row() {
                Text(`作者：${this.formatString(this.vm.detail?.author)}`)
                  .width('100%')
                  .fontSize(14)
                  .fontColor($r('app.color.custom_pink'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .onClick(() => {
                    this.vm.goSearch(SearchType.Author, this.vm.detail?.author)
                  })
              }
              .margin({ top: 5 })

              Row() {
                Text(`汉化组：${this.formatString(this.vm.detail?.chineseTeam)}`)
                  .width('100%')
                  .fontSize(14)
                  .fontColor($r('app.color.custom_pink'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .onClick(() => {
                    this.vm.goSearch(SearchType.Team, this.vm.detail?.chineseTeam)
                  })
              }
              .margin({ top: 5 })

              Row() {
                Text(`分类：${this.vm.detail?.categories.join(',')}`)
                  .width('100%')
                  .fontSize(14)
                  .fontColor(Color.Gray)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .margin({ top: 5 })

              Row() {
                Row() {
                  Image($r('app.media.ic_public_heart'))
                    .width(14)
                    .fillColor($r('app.color.custom_pink'))
                  Text(`${this.formatNumber(this.vm.detail?.likesCount)}`)
                    .fontColor(Color.Gray)
                    .fontSize(14)
                    .margin({ left: 5 })
                }

                Row() {
                  Image($r('app.media.ic_public_eye'))
                    .width(14)
                    .fillColor($r('app.color.custom_pink'))
                  Text(`${this.formatNumber(this.vm.detail?.viewsCount)}`)
                    .fontColor(Color.Gray)
                    .fontSize(14)
                    .margin({ left: 5 })
                }
                .margin({ left: 15 })

                Row() {
                  Image($r('app.media.ic_public_book'))
                    .width(14)
                    .fillColor($r('app.color.custom_pink'))
                  Text(`${this.formatNumber(this.vm.detail?.epsCount)}`)
                    .fontColor(Color.Gray)
                    .fontSize(14)
                    .margin({ left: 5 })
                }
                .margin({ left: 15 })
              }
              .width('100%')
              .margin({ top: 5 })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .constraintSize({ minHeight: 150 })
          .padding({
            left: 5,
            right: 5,
            top: 15,
            bottom: 15
          })

          // 标签组
          Flex({
            wrap: FlexWrap.Wrap,
            space: {
              main: { value: 10, unit: LengthUnit.VP },
              cross: { value: 10, unit: LengthUnit.VP }
            }
          }) {
            ForEach(this.vm.detail?.tags, (key: string) => {
              Chip({
                label: {
                  text: key,
                  fontSize: 14,
                  fontColor: Color.White
                },
                backgroundColor: $r('app.color.custom_pink'),
                allowClose: false,
                size: ChipSize.SMALL,
                onClicked: () => {
                  this.vm.goSearch(SearchType.Custom, key)
                }
              })
            })
          }
          .width('100%')
          .margin({ bottom: 15 })

          // 描述
          Text(this.vm.detail?.description)
            .width('100%')
            .fontSize(16)
            .fontColor(Color.Gray)
            .margin({ bottom: 15 })

          // 按钮组
          Row() {
            // 开始阅读
            Column() {
              Button(this.vm.currentOrder > 0 ? '继续阅读' : '开始阅读')
                .width('80%')
                .backgroundColor($r('app.color.custom_pink'))
                .onClick(() => {
                  this.vm.goToReader(this.vm.currentOrder > 0 ? this.vm.currentOrder : 1)
                })
            }
            .width('49%')

            // 收藏
            Column() {
              Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
                SymbolGlyph(this.vm.detail?.isFavourite ? $r('sys.symbol.star_fill') : $r('sys.symbol.star'))
                  .fontSize(40)
                  .fontColor([this.vm.detail?.isFavourite ? $r('app.color.custom_pink') : Color.Gray])
                  .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE))
              }
              .type(ButtonType.Circle)
              .stateEffect(false)
              .onClick(() => {
                this.vm.toggleFavourite()
              })
            }
            .width('17%')

            // 喜欢
            Column() {
              Badge({
                count: this.vm.detail ? this.vm.detail.likesCount : 0,
                maxCount: this.vm.detail ? this.vm.detail.likesCount : 99,
                position: BadgePosition.RightTop,
                style: { badgeSize: 16, badgeColor: '#FA2A2D' }
              }) {
                Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
                  SymbolGlyph(this.vm.detail?.isLiked ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
                    .fontSize(40)
                    .fontColor([this.vm.detail?.isLiked ? $r('app.color.custom_pink') : Color.Gray])
                    .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE))
                }
                .type(ButtonType.Circle)
                .stateEffect(false)
                .onClick(() => {
                  this.vm.toggleLike()
                })
              }
            }
            .width('17%')

            // 评论
            Column() {
              Badge({
                count: this.vm.detail ? this.vm.detail.commentsCount : 0,
                maxCount: this.vm.detail ? this.vm.detail.commentsCount : 99,
                position: BadgePosition.RightTop,
                style: { badgeSize: 16, badgeColor: '#FA2A2D' }
              }) {
                Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
                  SymbolGlyph($r('sys.symbol.message_on_message_fill'))
                    .fontSize(40)
                    .fontColor([Color.Gray])
                    .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE))
                }
                .type(ButtonType.Circle)
                .stateEffect(false)
                .onClick(() => {
                  this.vm.toggleComments(true)
                })
              }
            }
            .width('17%')
            .enabled(!this.vm.showComments)
            .bindSheet(this.vm.showComments!!, this.comments(), {
              title: {
                title: '评论区',
                subtitle: '发表你的观点吧~',
              },
              height: SheetSize.MEDIUM,
              preferType: SheetType.CENTER,
              showClose: false,
              dragBar: false,
              blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
              onWillDismiss: () => {
                this.vm.toggleComments(false)
              }
            })
          }
          .margin({ bottom: 15 })

          // 骑士信息
          Row() {
            // 头像
            Column() {
              ImageKnifeComponent({
                imageKnifeOption: {
                  loadSrc: this.creatorAvatar(),
                  border: {
                    radius: 50,
                    width: 2,
                    color: $r('app.color.custom_pink')
                  }
                }
              })
                .width(48)
                .height(48)
            }
            .width(48)
            .height(48)
            .margin({ right: 15 })
            .onClick(() => {
              this.vm.goSearch(SearchType.Uploader, this.vm.detail?._creator._id, this.vm.detail?._creator.name)
            })

            // 昵称 + 更新日期
            Column() {
              Text(`${this.vm.detail?._creator.name}`)
                .fontWeight(FontWeight.Bold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Start)
                .width('100%')

              Text(`${DateUtil.getFormatDateStr(new Date(this.vm.detail?.created_at), 'yyyy年MM月dd日 HH:mm')}更新`)
                .width('100%')
                .fontSize(14)
                .fontColor(Color.Gray)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Start)
                .margin({ top: 5 })
            }
            .height(48)
            .layoutWeight(1)
          }
          .width('100%')
          .height(48)
          .margin({ bottom: 15 })
          .padding({ left: 15, right: 15 })

          // 章节信息
          Column() {
            Flex({
              wrap: FlexWrap.Wrap,
              space: {
                main: { value: 10, unit: LengthUnit.VP },
                cross: { value: 10, unit: LengthUnit.VP }
              }
            }) {
              ForEach(this.vm.eps, (ep: ComicEp) => {
                Button() {
                  Text(ep.title)
                    .fontColor(this.vm.currentOrder === ep.order ? Color.White : $r('app.color.custom_pink'))
                    .maxLines(2)
                    .minFontSize(10)
                    .maxFontSize(16)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .heightAdaptivePolicy(TextHeightAdaptivePolicy.MAX_LINES_FIRST)
                    .margin(3)
                }
                .width(105)
                .height(40)
                .buttonStyle(ButtonStyleMode.TEXTUAL)
                .type(ButtonType.Normal)
                .borderWidth(2)
                .borderColor($r('app.color.custom_pink'))
                .borderRadius(10)
                .backgroundColor(this.vm.currentOrder === ep.order ? $r('app.color.custom_pink') : $r('app.color.listitem_background'))
                .onClick(() => {
                  this.vm.goToReader(ep.order)
                })
              })
            }
          }
          .width('100%')
          .margin({ bottom: 15 })
          .padding({ left: 15, right: 15 })

          // 相关推荐
          Column() {
            Text('相关推荐')
              .width('100%')
              .margin(10)
            ComicCardScroll({
              comics: this.vm.recommend,
              onCardClick: (comic) => {
                this.vm.goDetail(comic)
              }
            })
          }
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .padding({ left: 10, right: 10, bottom: PicState.bottomRectHeight })

    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.start_window_background'))
    .mode(NavDestinationMode.STANDARD)
    .padding({top: PicState.topRectHeight})
    .foregroundBlurStyle(PicState.foregroundBlurMode ? BlurStyle.Thin : BlurStyle.NONE)
    .onReady(async (context: NavDestinationContext) => {
      this.vm.init(context.pathStack, context.pathInfo.param as ComicCardInterface)
    })
    .onShown(async () => {
      this.vm.onPageShown()
    })
  }

  @Builder
  comments() {
    CommentList({
      comicId: this.vm.comic?.id,
      onComicClick: (comic) => {
        this.vm.goDetail(comic)
      }
    })
      .margin({ bottom: PicState.bottomRectHeight })
  }

  formatString(str?: string): string {
    if (str === undefined) {
      return '未知'
    }
    return str
  }

  creatorAvatar(): string {
    const avatar = this.vm.detail?._creator.avatar
    return avatar ? buildImageUrl(avatar) : ''
  }

  formatNumber(num?: number): number {
    if (num === undefined) {
      return 0
    }
    return num
  }

}


