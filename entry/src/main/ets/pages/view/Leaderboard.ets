import { BackType, TitleBar, TitleType } from '../component/TitleBar'
import ComicList from '../component/ComicList'
import { ComicResponse, knightLeaderboard, leaderboard } from '../../api/comic'
import { TimeType, User } from '../../api/models'
import { SlidingTabsV1 } from '@xqw/sliding-tabs'
import { SlidingTabControllerV1 } from '@xqw/sliding-tabs/src/main/ets/v1/SlidingTabControllerV1'
import { ImageKnifeComponent } from '@ohos/imageknife'
import { PreferenceStorageKey } from '../../utils/Preference'
import { ComicListOptions, SearchType } from './Comics'

@Builder
export function LeaderboardBuilder(name: string, param: Object) {
  Leaderboard()
}

/**
 * 排行榜
 */
@Component
export default struct Leaderboard {
  // 状态栏高度
  @StorageProp('topRectHeight') topRectHeight: number = 0
  // 导航栏高度
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
  @Consume('pageStack') pageStack: NavPathStack
  @State currentIndex: number = 0
  @State tabs: string[] = ['日榜', '周榜', '月榜', '骑士榜']
  @State knights: User[] = []
  @State isRefreshing: boolean = true
  swiperController = new SwiperController()
  tabController = new SlidingTabControllerV1(this.swiperController)

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
          titleBarColor: $r('app.color.start_window_background'),
          statusBarColor: $r('app.color.start_window_background'),
          centerLeftPadding: 60,
          centerType: TitleType.TEXT,
          centerText: '排行榜',
          centerTextColor: $r('app.color.common_button_background_light'),
          leftBackType: BackType.NONE,
          leftBackFillColor: $r('app.color.common_button_background_light'),
          leftOnClick: () => {
            this.pageStack.pop()
          },
        })

        Column() {
          // tab栏
          SlidingTabsV1({
            index: this.currentIndex,
            tabs: this.tabs,
            barMode: 'fixed',
            controller: this.tabController,
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
                canSwipe: false
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
                canSwipe: false
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
                canSwipe: false
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
                          ImageKnifeComponent({
                            imageKnifeOption: {
                              loadSrc: this.imageApi + knight.avatar?.path,
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
                        this.pageStack.pushPath({
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
        top: this.topRectHeight,
        bottom: this.bottomRectHeight,
        left: 10,
        right: 10
      })
    }.backgroundColor($r('app.color.start_window_background'))
    .mode(NavDestinationMode.STANDARD)
    .hideTitleBar(true)
  }
}