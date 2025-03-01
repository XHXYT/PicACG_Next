import { collections, ComicResponse, leaderboard, otherRecommend, random } from '../../api/comic'
import { ComicCardInterface } from '../component/ComicCard'
import { LogUtil } from '@pura/harmony-utils'
import ComicCardScroll from '../component/ComicCardScroll'
import { PreferenceStorageKey } from '../../utils/Preference'
import { ReplaceImageApi } from '../../common/Consts'
import { deviceInfo } from '@kit.BasicServicesKit'
import { TimeType } from '../../api/models'
import { LengthMetrics } from '@kit.ArkUI'
import ComicMainList from '../component/ComicMainList'
import { BreakpointState } from '../../utils/BreakPoint'

/**
 * 主界面
 */
@Component
export default struct Main {
  @StorageProp(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @Consume('MainGridColHeight') mainGridColHeight: BreakpointState<number>
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
  @Consume('MainEndOffset') mainEndOffset: BreakpointState<number>
  @Consume('CompStr') compStr: BreakpointState<string>
  @State random: ComicCardInterface[] = []
  @State recommend: ComicCardInterface[] = []
  @State collections: ComicCardInterface[] = []
  @State currentIndex: number = 0
  @State private currentBreakpoint: string = 'md'
  @State animationDuration: number = 300
  @State indicatorLeftMargin: number = 0
  @State indicatorWidth: number = 0
  private textInfos: [number, number][] = []

  aboutToAppear() {
    // 加载本子妹推荐
    // this.loadCollection()
    // 加载随机推荐
    this.loadRecommend()
    // 加载随机本子
    this.loadRandom()
  }

  // 排行榜接口
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

  // 加载随机推荐
  loadRecommend() {
    otherRecommend().then(res => {
      animateTo({ duration: 300 }, () => {
        res.forEach((comic) => {
          this.recommend.push({
            id: comic.id,
            title: comic.title,
            image: ReplaceImageApi(comic.pic)
          })
        })
      })
      LogUtil.info(`随机推荐: ${res.length}`)
    }).catch((err: Error) => {
      LogUtil.error(`错误: ${err.message}`)
      LogUtil.error(err.stack)
    })
  }

  // 加载随机本子
  loadRandom() {
    random().then(res => {
      animateTo({ duration: 300 }, () => {
        res.comics.forEach((comic) => {
          this.random.push({
            id: comic._id,
            title: `${comic.title}（${comic.pagesCount}P）${comic.finished ? '（完）' : ''}`,
            image: `${this.imageApi}${comic.thumb.path}`
          })
        })
      })
    }).catch((err: Error) => {
      LogUtil.error(`错误: ${err.message}`)
      LogUtil.error(err.stack)
    })
  }

  // 加载本子妹推荐
  loadCollection() {
    collections().then(res => {
      res.collections.forEach((collection) => {
        LogUtil.info(`${collection.title}: ${collection.comics.length}`)
        animateTo({ duration: 300 }, () => {
          collection.comics.forEach((comic) => {
            this.collections.push({
              id: comic._id,
              title: `${comic.title}（${comic.pagesCount}P）${comic.finished ? '（完）' : ''}`,
              image: `${this.imageApi}${comic.thumb.path}`
            })
          })
        })
      })
    }).catch((err: Error) => {
      LogUtil.error(`错误: ${err.message}`)
      LogUtil.error(err.stack)
    })
  }

  build() {
    List() {
      ListItem() {
        GridRow() {
          // 排行榜
          GridCol({
            span: {sm: 12, md: deviceInfo.deviceType === 'tablet' ? 12 : 7, lg: 7},
            order: 1
          }) {
            Column({space: 2}) {
              Text('排行榜')
                .width('100%')
              Flex({
                direction: FlexDirection.Row,
                justifyContent: FlexAlign.Center,
                alignItems: ItemAlign.Center,
                space: { main: LengthMetrics.vp(3) }
              }) {
                // 日榜
                Stack() {
                  ComicMainList({
                    attr: {
                      type: 'remote', api: () => {
                        return this.api(TimeType.Hour24)
                      }
                    },
                    canSwipe: false
                  })
                }.height('100%')
                // 周榜
                Stack() {
                  ComicMainList({
                    attr: {
                      type: 'remote', api: () => {
                        return this.api(TimeType.Day7)
                      }
                    },
                    canSwipe: false
                  })
                }.height('100%')
                if (this.compStr.value !== 'sm') {
                  // 月榜
                  Stack() {
                    ComicMainList({
                      attr: {
                        type: 'remote', api: () => {
                          return this.api(TimeType.Day30)
                        }
                      },
                      canSwipe: false
                    })
                  }.height('100%')
                }
              }
              .width('100%')
              .margin({bottom: 10})
              .height(deviceInfo.deviceType === 'tablet' ? 650 : this.mainGridColHeight.value)
            }
          }

          GridCol({
            span: {sm: 12, md: deviceInfo.deviceType === 'tablet' ? 12 : 5, lg: 5},
            order: 2
          }) {
            Column({space: 5}) {
              // 随机推荐区
              Column({space: 10}) {
                Text('随机推荐')
                  .width('100%')
                ComicCardScroll({ comics: this.recommend })
              }
              // 随机本子区
              Column({space: 10}) {
                Text('随机本子')
                  .width('100%')
                ComicCardScroll({ comics: this.random })
              }
            }.width('100%')
            // .height((this.currentBreakpoint === 'md' && deviceInfo.deviceType !== 'phone' || this.compStr.value === 'sm' ) ? '50%' : '100%')
            .justifyContent(FlexAlign.SpaceAround)
            .alignItems(HorizontalAlign.Center)
          }.layoutWeight(1)

          // 本子妹推荐区
          /*GridCol({
            span: {sm: 12, md: deviceInfo.deviceType === 'phone' ? 6 : 12, lg: 6},
            order: 3
          }) {
            Column({space: 10}) {
              Text('本子妹推荐')
                .width('100%')
              ComicCardScroll({ comics: this.recommend, })
            }.width('100%')
            // .height((this.currentBreakpoint === 'md' && deviceInfo.deviceType !== 'phone') ? '40%' : '100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }.borderWidth(2).borderColor(Color.Green)*/

        }.width('100%').height('100%')
        .onBreakpointChange((breakpoint: string) => {
          this.currentBreakpoint = breakpoint;
        })
      }
    }.backgroundColor($r('app.color.start_window_background'))
    .scrollBar(BarState.Off)
    .contentEndOffset(this.mainEndOffset.value)
    .width('100%')
    .padding(10)
  }

  @Builder
  tabBuilder(index: number, name: string) {
    Column() {
      Text(name)
        .fontColor(this.currentIndex === index ? $r('app.color.common_button_background_weight') : Color.Gray)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .id(index.toString())
        .onAreaChange((_oldValue: Area, newValue: Area) => {
          this.textInfos[index] = [newValue.globalPosition.x as number, newValue.width as number]
        })
    }.width('100%')
  }
}