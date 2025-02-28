import { ImageKnifeComponent } from '@ohos/imageknife'
import { DateUtil, LogUtil } from '@pura/harmony-utils'
import { detail, eps, recommendation } from '../../api/comic'
import { ComicDetailInfo, ComicEp } from '../../api/models'
import { PreferenceStorageKey } from '../../utils/Preference'
import { ComicCardInterface } from '../component/ComicCard'
import { BackType, TitleBar, TitleType } from '../component/TitleBar'
import { Chip, ChipSize, LengthUnit, promptAction } from '@kit.ArkUI'
import { ComicListOptions, SearchType } from './Comics'
import ComicCardScroll from '../component/ComicCardScroll'
import CommentList from '../component/CommentList'
import { favouriteAction, likeAction } from '../../api/profile'
import { ComicChapterInterface } from './ComicReader'
import { HistoryUtil } from '../../utils/History'
import HalfModal from '../component/HalfModal'

@Builder
export function ComicDetailBuilder(name: string, param: Object) {
  ComicDetail()
}

@Component
export default struct ComicDetail {
  // 状态栏高度
  @StorageProp('topRectHeight') topRectHeight: number = 0
  // 导航条高度
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @StorageProp(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
  @Consume('pageStack') pageStack: NavPathStack
  @State comic: ComicCardInterface | undefined = undefined
  @State detail: ComicDetailInfo | undefined = undefined
  @State eps: ComicEp[] = []
  @State recommend: ComicCardInterface[] = []
  @State showComments: boolean = false
  @State currentOrder: number = 0

  build() {
    NavDestination() {
      TitleBar({
        titleBarColor: $r('app.color.start_window_background'),
        statusBarColor: $r('app.color.start_window_background'),
        centerType: TitleType.NONE,
        leftBackType: BackType.NONE,
        leftBackFillColor: $r('app.color.common_button_background_light'),
        leftOnClick: () => {
          this.pageStack.pop()
        },
      })

      Scroll(new Scroller()) {
        Column() {
          // 顶部基本信息
          Row() {
            Column() {
              ImageKnifeComponent({
                imageKnifeOption: {
                  loadSrc: this.comic?.image,
                  placeholderSrc: $r('app.media.loading'),
                  border: { radius: 6 },
                }
              })
                .width(86)
            }
            .margin({ right: 15 })
            .borderRadius(6)
            .foregroundBlurStyle(this.privacyMode ? BlurStyle.Thin : BlurStyle.NONE)

            Column() {
              Row() {
                Text(`${this.comic?.title}`)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }

              Row() {
                Text(`作者：${this.formatString(this.detail?.author)}`)
                  .width('100%')
                  .fontSize(14)
                  .fontColor($r('app.color.custom_pink'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .onClick(() => {
                    this.pageStack.pushPath({
                      name: 'Comics',
                      param: {
                        type: SearchType.Author,
                        key: this.detail?.author
                      } as ComicListOptions
                    })
                  })
              }
              .margin({ top: 5 })

              Row() {
                Text(`汉化组：${this.formatString(this.detail?.chineseTeam)}`)
                  .width('100%')
                  .fontSize(14)
                  .fontColor($r('app.color.custom_pink'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .onClick(() => {
                    this.pageStack.pushPath({
                      name: 'Comics',
                      param: {
                        type: SearchType.Team,
                        key: this.detail?.chineseTeam
                      } as ComicListOptions
                    })
                  })
              }
              .margin({ top: 5 })

              Row() {
                Text(`分类：${this.detail?.categories.join(',')}`)
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
                  Text(`${this.formatNumber(this.detail?.likesCount)}`)
                    .fontColor(Color.Gray)
                    .fontSize(14)
                    .margin({ left: 5 })
                }

                Row() {
                  Image($r('app.media.ic_public_eye'))
                    .width(14)
                    .fillColor($r('app.color.custom_pink'))
                  Text(`${this.formatNumber(this.detail?.viewsCount)}`)
                    .fontColor(Color.Gray)
                    .fontSize(14)
                    .margin({ left: 5 })
                }
                .margin({ left: 15 })

                Row() {
                  Image($r('app.media.ic_public_book'))
                    .width(14)
                    .fillColor($r('app.color.custom_pink'))
                  Text(`${this.formatNumber(this.detail?.epsCount)}`)
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
          .height(150)
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
            ForEach(this.detail?.tags, (key: string) => {
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
                  this.pageStack.pushPathByName(
                    'Comics',
                    { type: SearchType.Custom, key: key } as ComicListOptions,
                  )
                }
              })
            })
          }
          .width('100%')
          .margin({ bottom: 15 })

          // 描述
          Text(this.detail?.description)
            .width('100%')
            .fontSize(16)
            .fontColor(Color.Gray)
            .margin({ bottom: 15 })

          // 按钮组
          Row() {
            // 开始阅读
            Column() {
              Button(this.currentOrder > 0 ? '继续阅读' : '开始阅读')
                .width('80%')
                .backgroundColor($r('app.color.custom_pink'))
                .onClick(() => {
                  this.goToReader(this.currentOrder > 0 ? this.currentOrder : 1)
                })
            }
            .width('49%')

            // 收藏
            Column() {
              Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
                SymbolGlyph(this.detail?.isFavourite ? $r('sys.symbol.star_fill') : $r('sys.symbol.star'))
                  .fontSize(40)
                  .fontColor([this.detail?.isFavourite ? $r('app.color.custom_pink') : Color.Gray])
                  .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE))
              }
              .type(ButtonType.Circle)
              .stateEffect(false)
              .onClick(() => {
                if (this.detail) {
                  this.detail.isFavourite = !this.detail.isFavourite
                  favouriteAction(this.detail._id).then(res => {
                    if (res.action === 'favourite') {
                      promptAction.showToast({ message: '收藏成功', });
                    } else {
                      promptAction.showToast({ message: '取消收藏成功', });
                    }
                  })
                }
                LogUtil.info('点击收藏')
              })
            }
            .width('17%')

            // 喜欢
            Column() {
              Badge({
                count: this.detail ? this.detail.likesCount : 0,
                maxCount: this.detail ? this.detail.likesCount : 99,
                position: BadgePosition.RightTop,
                style: { badgeSize: 16, badgeColor: '#FA2A2D' }
              }) {
                Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
                  SymbolGlyph(this.detail?.isLiked ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
                    .fontSize(40)
                    .fontColor([this.detail?.isLiked ? $r('app.color.custom_pink') : Color.Gray])
                    .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE))
                }
                .type(ButtonType.Circle)
                .stateEffect(false)
                .onClick(() => {
                  if (this.detail) {
                    this.detail.isLiked = !this.detail.isLiked
                    likeAction(this.detail._id).then(res => {
                      if (res.action === 'like') {
                        promptAction.showToast({ message: '喜欢成功', });
                      } else {
                        promptAction.showToast({ message: '取消喜欢成功', });
                      }
                    })
                  }
                  LogUtil.info('点击喜欢')
                })
              }
            }
            .width('17%')

            // 评论
            Column() {
              Badge({
                count: this.detail ? this.detail.commentsCount : 0,
                maxCount: this.detail ? this.detail.commentsCount : 99,
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
                  LogUtil.info('点击评论')
                  this.showComments = true
                })
              }
            }
            .width('17%')
            .enabled(!this.showComments)
          }
          .margin({ bottom: 15 })

          // 骑士信息
          Row() {
            // 头像
            Column() {
              ImageKnifeComponent({
                imageKnifeOption: {
                  loadSrc: this.imageApi + this.detail?._creator.avatar?.path,
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
              this.pageStack.pushPath({
                name: 'Comics',
                param: {
                  type: SearchType.Uploader,
                  key: this.detail?._creator._id,
                  title: this.detail?._creator.name
                } as ComicListOptions
              })
            })

            // 昵称 + 更新日期
            Column() {
              Text(`${this.detail?._creator.name}`)
                .fontWeight(FontWeight.Bold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Start)
                .width('100%')

              Text(`${DateUtil.getFormatDateStr(new Date(this.detail?.created_at), 'yyyy年MM月dd日 HH:mm')}更新`)
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
              ForEach(this.eps, (ep: ComicEp) => {
                Button() {
                  Text(ep.title)
                    .fontColor(this.currentOrder === ep.order ? Color.White : $r('app.color.custom_pink'))
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
                .backgroundColor(this.currentOrder === ep.order ? $r('app.color.custom_pink') : $r('app.color.listitem_background'))
                .onClick(() => {
                  this.goToReader(ep.order)
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
            ComicCardScroll({ comics: this.recommend, })
          }
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .padding({ left: 10, right: 10, bottom: this.bottomRectHeight })

      HalfModal({
        show: this.showComments,
        view: () => {
          this.comments()
        },
        options: {
          title: {
            title: '评论区',
            subtitle: '发表你的观点吧~',
          },
          height: SheetSize.MEDIUM,
          showClose: false,
          dragBar: false,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          onDisappear: () => {
            this.showComments = false
          },
        }
      })
    }
    .hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
    .padding({top: this.topRectHeight})
    .onReady((context: NavDestinationContext) => {
      this.comic = context.pathInfo.param as ComicCardInterface
      LogUtil.info('本子详情页：', this.comic.id, ' - ', this.comic.title)
      detail(this.comic.id).then(res => {
        animateTo({ duration: 300 }, () => {
          this.detail = res.comic
        })
      })

      this.loadEps(this.comic.id, 1)

      recommendation(this.comic.id).then(res => {
        res.comics.forEach((comic) => {
          animateTo({ duration: 300 }, () => {
            this.recommend.push({
              id: comic._id,
              title: `${comic.title}（${comic.pagesCount}P）${comic.finished ? '（完）' : ''}`,
              image: `${this.imageApi}${comic.thumb.path}`
            })
          })
        })
      })

      HistoryUtil.getRead(this.comic.id).then(res => {
        this.currentOrder = res
      })
    })
    .onShown(() => {
      if (this.detail) {
        HistoryUtil.getRead(this.detail._id).then(res => {
          this.currentOrder = res
        })
      }
    })
  }

  @Builder
  comments() {
    CommentList({ comicId: this.comic?.id })
      .margin({ bottom: this.bottomRectHeight })
  }

  loadEps(id: string, page: number) {
    eps(id, page).then(res => {
      animateTo({ duration: 300 }, () => {
        this.eps.push(...res.eps.docs)
        if (page < res.eps.pages) {
          LogUtil.info(`递归加载所有章节：${page + 1}-${res.eps.pages}`)
          this.loadEps(id, page + 1)
        }
      })
    })
  }

  goToReader(chapter: number) {
    if (this.detail) {
      HistoryUtil.add(this.detail)
      this.pageStack.pushPathByName(
        'ComicReader',
        { comicId: this.detail._id, order: chapter } as ComicChapterInterface
      )
    }
  }

  formatString(str?: string): string {
    if (str === undefined) {
      return '未知'
    }
    return str
  }

  formatNumber(num?: number): number {
    if (num === undefined) {
      return 0
    }
    return num
  }
}