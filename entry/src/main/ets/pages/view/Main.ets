import { collections, ComicResponse, leaderboard, otherRecommend, random } from '../../api/comic'
import { ComicCardInterface } from '../component/ComicCard'
import { LogUtil } from '@pura/harmony-utils'
import ComicCardScroll from '../component/ComicCardScroll'
import { PreferenceStorageKey } from '../../utils/Preference'
import { ReplaceImageApi } from '../../common/Consts'
import { deviceInfo } from '@kit.BasicServicesKit'
import { TimeType } from '../../api/models'
import { LengthMetrics } from '@kit.ArkUI'
import ComicBanner from '../component/ComicBanner'
import { BreakpointState } from '../../utils/BreakPoint'

/**
 * 主界面
 */
@Component
export default struct Main {

  @StorageProp(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
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

  build() {
    List() {
      // 排行榜-日榜-轮播图
      ListItem() {
        ComicBanner({
          attr: {
            type: 'remote', api: () => {
              return this.api(TimeType.Hour24)
            }
          },
          canSwipe: false
        })
      }
      // 随机推荐区
      ListItem() {
        Column({space: 5}) {
          Column({space: 7}) {
            Text('随机推荐').width('100%').margin({top: 3})
            ComicCardScroll({ comics: this.recommend })
          }
        }.width('100%')
        .backgroundColor($r('app.color.start_window_background'))
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(HorizontalAlign.Center)
      }
      // 随机本子区
      ListItem() {
        Column({space: 5}) {
          Column({space: 7}) {
            Text('随机本子').width('100%')
            ComicCardScroll({ comics: this.random })
          }
        }.width('100%')
        .backgroundColor($r('app.color.start_window_background'))
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(HorizontalAlign.Center)
      }
      ListItem() {
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
      }
    }
    .alignListItem(ListItemAlign.Start)
    .backgroundColor($r('app.color.start_window_background'))
    .scrollBar(BarState.Off)
    .height('100%')
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

  // 排行榜接口
  api(t: TimeType): Promise<ComicResponse> {
    return new Promise<ComicResponse>((resolve, reject) => {
      leaderboard(t).then((res) => {
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

}