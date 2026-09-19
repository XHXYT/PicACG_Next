import { TitleBar } from '../component/TitleBar'
import ComicList from '../component/ComicList'
import { ComicResponse, knightLeaderboard, leaderboard } from '../../api/comic'
import { TimeType, User } from '../../api/models'
import { SlidingTabControllerV2 } from '@xqw/sliding-tabs/src/main/ets/v2/SlidingTabControllerV2'
import { ImageKnifeComponentV2 } from '@ohos/imageknifepro'
import { SlidingTabsV2 } from '@xqw/sliding-tabs'
import { ComicListOptions, SearchType } from '../../common/Model'
import { PicState } from '../../entryability/AppState'
import { buildImageUrl } from '../../common/Consts'

@Builder
export function LeaderboardBuilder(name: string, param: Object) {
  Leaderboard()
}

/**
 * 排行榜
 */
@ComponentV2
export default struct Leaderboard {

  @Local currentIndex: number = 0
  @Local tabs: string[] = ['日榜', '周榜', '月榜', '骑士榜']
  @Local knights: User[] = []
  @Local isRefreshing: boolean = true
  @Local pageInfos: NavPathStack = new NavPathStack()

  swiperController = new SwiperController()
  tabController: SlidingTabControllerV2 = new SlidingTabControllerV2()

  api(t: TimeType): Promise<ComicResponse> {
    return new Promise<ComicResponse>((resolve, reject) => {
      leaderboard(t).then(res => {
        resolve({
          comics: {
            docs: res.comics,
            page: 1,
            pages: 1,
            total: res.comics.length,
            limit: res.comics.length,
          }
        })
      }).catch((err: Error) => {
        reject(err)
      })
    })
  }

  build() {
    NavDestination() {
      Column() {
        // 标题栏
        TitleBar({
          title: '排行榜',
        })

        Column() {
          // tab栏
          SlidingTabsV2({
            tabs: this.tabs,
            barMode: 'fixed',
            tabController: this.tabController,
            onChange: (index: number) => {
              this.currentIndex = index;
              this.swiperController.changeIndex(index)
            },
            tabStyle: {
              fontColor: Color.Gray,
              fontColorSelect: $r('app.color.common_button_background_light'),
              fontWeightSelect: FontWeight.Medium,
            },
            indicatorStyle: {
              color: $r('app.color.common_button_background_light'),
              width: 60
            }
          })
          // 详情列表
          Swiper(this.swiperController) {
            // 日榜
            Stack() {
              ComicList({
                attr: {
                  type: 'remote', api: () => {
                    return this.api(TimeType.Hour24)
                  }
                },
                canSwipe: false,
                onItemClick: (comic) => {
                  this.pageInfos.pushPathByName('comic_detail', comic)
                }
              })
            }
            .width('100%').height('100%')
            // 周榜
            Stack() {
              ComicList({
                attr: {
                  type: 'remote', api: () => {
                    return this.api(TimeType.Day7)
                  }
                },
                canSwipe: false,
                onItemClick: (comic) => {
                  this.pageInfos.pushPathByName('comic_detail', comic)
                }
              })
            }
            .width('100%').height('100%')
            // 月榜
            Stack() {
              ComicList({
                attr: {
                  type: 'remote', api: () => {
                    return this.api(TimeType.Day30)
                  }
                },
                canSwipe: false,
                onItemClick: (comic) => {
                  this.pageInfos.pushPathByName('comic_detail', comic)
                }
              })
            }
            .width('100%').height('100%')
            // 骑士榜
            Stack() {
              Refresh({ refreshing: $$this.isRefreshing }) {
                List({ space: 5, scroller: new Scroller() }) {
                  ForEach(this.knights, (knight: User) => {
                    ListItem() {
                      Row() {
                        // 骑士榜 =>头像
                        Column() {
                          ImageKnifeComponentV2({
                            imageKnifeOption: {
                              loadSrc: knight.avatar ? buildImageUrl(knight.avatar) : '',
                              border: {
                                radius: 50,
                                width: 2,
                                color: $r('app.color.custom_pink')
                              }
                            }
                          })
                            .width(64)
                            .height(64)
                        }
                        .width(64)
                        .height(64)
                        .margin({ right: 15 })

                        // 骑士榜 => 昵称 + 等级 + 更新数量
                        Column() {
                          Text(`${knight.name}`)
                            .fontWeight(FontWeight.Bold)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .textAlign(TextAlign.Start)
                            .width('100%')

                          Text(`LV ${knight.level}`)
                            .fontColor($r('app.color.common_button_background_light'))
                            .maxLines(1)
                            .textAlign(TextAlign.Start)
                            .width('100%')

                          Row() {
                            Image($r('app.media.ic_public_book'))
                              .width(18)
                              .padding({ right: 5 })
                              .fillColor($r('app.color.common_button_background_light'))
                            Text(`${knight.comicsUploaded}`)
                              .width('100%')
                              .fontColor($r('app.color.common_button_background_light'))
                          }
                          .width('100%')
                        }
                        .height(64)
                        .layoutWeight(1)
                      }
                      .width('100%')
                      .height(80)
                      .onClick(() => {
                        this.pageInfos.pushPath({
                          name: 'Comics',
                          param: {
                            type: SearchType.Uploader,
                            key: knight._id,
                            title: knight.name
                          } as ComicListOptions
                        })
                      })
                    }
                  })
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
              }
              .onRefreshing(() => {
                animateTo({ duration: 500 }, () => {
                  knightLeaderboard().then(res => {
                    this.knights = res.users
                  }).finally(() => {
                    this.isRefreshing = false
                  })
                })
              })
              .layoutWeight(1)
              .refreshOffset(64)
              .pullToRefresh(true)
            }
            .width('100%').height('100%')
          }
          .margin({ top: 10 })
          .indicator(false)
          .layoutWeight(1)
          .onGestureSwipe((index, extraInfo) => {
            this.tabController.swiperOnGestureSwipe(index, extraInfo)
          })
          .onAreaChange((oldValue, newValue) => {
            this.tabController.swiperOnAreaChange(oldValue, newValue)
          })
          .onAnimationStart((index, targetIndex, extraInfo) => {
            this.tabController.swiperOnAnimationStart(index, targetIndex, extraInfo)
          })
        }
        .width('100%')
        .height('100%')
        .padding(10)
        .layoutWeight(1)
      }
      .height('100%')
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({
        top: PicState.topRectHeight,
        bottom: PicState.bottomRectHeight,
        left: 10,
        right: 10
      })
    }.backgroundColor($r('app.color.start_window_background'))
    .mode(NavDestinationMode.STANDARD)
    .hideTitleBar(true)
    .onReady((ctx) => {
      this.pageInfos = ctx.pathStack
    })
  }

}