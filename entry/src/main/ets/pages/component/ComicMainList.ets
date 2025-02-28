import { LogUtil } from '@pura/harmony-utils';
import { ComicResponse } from '../../api/comic';
import { ComicDetailInfo, ComicSimpleInfo, SortType } from '../../api/models';
import { favouriteAction } from '../../api/profile';
import { StorageKey } from '../../common/Consts';
import { HistoryUtil } from '../../utils/History';
import { PreferenceStorageKey } from '../../utils/Preference';
import ComicListItem from './ComicListItem';
import { promptAction } from '@kit.ArkUI';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { ComicCardInterface } from './ComicCard';

@Component
export default struct ComicMainList {
  @StorageProp(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
  @StorageProp(StorageKey.CATEGORY) category: string[] = []
  @StorageLink(StorageKey.FILTER_CATEGORY) filterCategory: string[] = []
  @Consume('pageStack') pageStack: NavPathStack
  @State comics: ComicDetailInfo[] = []
  @State isRefreshing: boolean = true
  @State isLoading: boolean = false;
  @State isEnd: boolean = false;
  @State maxPage: number = 1
  @State total: number = 0
  @State page: number = 1
  @Prop @Watch('attrChange') attr: ComicListAttribute
  @Prop canSwipe: boolean = true
  @Prop showFilter: boolean = false
  private scroll: Scroller = new Scroller()

  attrChange() {
    this.isRefreshing = true
  }

  loadComics() {
    if (this.attr.type === 'history') {
      LogUtil.debug('加载浏览历史')
      setTimeout(() => {
        this.loadHistory()
      }, 500)
    } else if (this.attr.type === 'remote') {
      LogUtil.debug('加载远程数据')
      this.loadRemote()
    }
  }

  loadHistory() {
    animateTo({ duration: 500 }, () => {
      HistoryUtil.get().then(res => {
        this.comics = res
        this.isRefreshing = false
        this.scroll.scrollEdge(Edge.Top)
      })
    })
  }

  loadRemote() {
    if (this.attr.api !== undefined) {
      this.attr.api(this.page, this.attr.sort, this.attr.param1, this.attr.param2)
        .then(res => {
          animateTo({ duration: 500 }, () => {
            if (this.page === 1) {
              this.comics = res.comics.docs
              this.scroll.scrollEdge(Edge.Top)
            } else {
              this.comics.push(...res.comics.docs)
            }
          })
          LogUtil.debug(`加载第${this.page}页，共${res.comics.docs.length}条`)
          this.page = res.comics.page
          this.maxPage = res.comics.pages
          this.total = res.comics.total
        })
        .finally(() => {
          animateTo({ duration: 500 }, () => {
            this.isRefreshing = false
            this.isLoading = false
          })
        })
    }
  }

  build() {
    Column() {
      if (this.showFilter) {
        Scroll(new Scroller()) {
          Row() {
            ForEach(this.category, (cate: string, index: number) => {
              Button(cate)
                .height(30)
                .stateEffect(false)
                .margin({ left: index === 0 ? 0 : 5 })
                .backgroundColor(
                  this.filterCategory.indexOf(cate) >= 0 ? Color.Gray : $r('app.color.common_button_background_weight')
                )
                .onClick(() => {
                  if (this.filterCategory.indexOf(cate) >= 0) {
                    this.filterCategory = this.filterCategory.filter(c => c !== cate)
                  } else {
                    this.filterCategory.push(cate)
                  }
                })
            })
          }
          .height(40)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      Refresh({ refreshing: $$this.isRefreshing }) {
        List({ space: 5, scroller: this.scroll }) {
          ForEach(this.comics, (comic: ComicDetailInfo) => {
            ListItem() {
              Column() {
                ImageKnifeComponent({
                  imageKnifeOption:
                  {
                    loadSrc: `${this.imageApi}${comic.thumb.path}`,
                    placeholderSrc: $r('app.media.loading'),
                    border: {radius:10}
                  }
                }).height(160)
                Text(comic.title)
                  .maxLines(1)
                  .fontColor($r('app.color.custom_pink'))
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .height(170)
              .borderRadius(10)
              .margin({ right: 16, top: 10, bottom: 10 })
              .foregroundBlurStyle(this.privacyMode ? BlurStyle.Thin : BlurStyle.NONE)
              .onClick(() => {
                if (this.showFilter && this.isFilter(comic.categories)) {
                  return
                }
                let comics: ComicCardInterface = {
                  id: comic._id,
                  image: `${this.imageApi}${comic.thumb.path}`,
                  title: comic.title
                }
                this.pageStack.pushPathByName('ComicDetail', comics)
              })
            }
            .layoutWeight(1)
            .height(undefined)
            .borderRadius(30)
            .transition(TransitionEffect.asymmetric(
              TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 300 }),
              TransitionEffect.move(TransitionEdge.START).animation({ duration: 300 })
            ))
            .swipeAction(this.canSwipe ? {
              end: {
                builder: () => {
                  this.itemEnd(comic)
                },
                onAction: () => {
                  LogUtil.info('onAction:触发删除操作')
                  this.operateFavourite(comic)
                },
                actionAreaDistance: 56,
              }
            } : undefined)
          }, (item: ComicSimpleInfo) => {
            return item._id
          })

          if (this.comics.length === this.total) {
            ListItem() {
              Row() {
                Text('没有更多了')
              }.width('100%')
              .height(64)
              .justifyContent(FlexAlign.Center)
            }
          }

          if (this.isLoading) {
            ListItem() {
              Row() {
                LoadingProgress().height(32).width(48)
              }.width('100%')
              .height(64)
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
        .divider({
          strokeWidth: 1,
          color: $r('app.color.custom_gray'),
          startMargin: 10,
          endMargin: 10
        })
        .scrollBar(BarState.Off)
        .onScrollIndex((_: number, end: number) => {
          LogUtil.info(`${end}`)
          this.isEnd = end + 5 >= this.comics.length
          if (this.isEnd && this.page < this.maxPage) {
            LogUtil.info('onReachEnd到底辣！！！要加载更多')
            this.page++
            animateTo({ duration: 500 }, () => {
              this.isLoading = true
              this.loadComics()
            })
          }
        })
      }
      .onRefreshing(() => {
        LogUtil.info('刷新！！！！')
        this.page = 1
        animateTo({ duration: 500 }, () => {
          this.loadComics()
        })
      })
      .layoutWeight(1)
      .refreshOffset(64)
      .pullToRefresh(true)
    }
    .layoutWeight(1)
  }

  @Builder
  itemEnd(comic: ComicSimpleInfo) {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: false, buttonStyle: ButtonStyleMode.TEXTUAL }) {
        Image($r('app.media.ic_public_delete'))
          .width(24)
          .fillColor(Color.White)
      }
      .width(40)
      .height(40)
      .margin(5)
      .type(ButtonType.Circle)
      .backgroundColor(Color.Red)
      .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.8 })
      .onClick(() => this.operateFavourite(comic))
    }
    .padding(4)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  operateFavourite(comic: ComicSimpleInfo) {
    favouriteAction(comic._id)
      .then(res => {
        if (res.action === 'un_favourite') {
          animateTo({ duration: 500 }, () => {
            this.comics = this.comics.filter(c => c._id !== comic._id)
          })
          promptAction.showToast({ message: '已取消收藏', });
        }
      })

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

export interface ComicListAttribute {
  type: 'history' | 'remote',
  api?: (page?: number, s?: SortType, p3?: string, p4?: string | string[]) => Promise<ComicResponse>
  sort?: SortType
  param1?: string
  param2?: string | string[]
}