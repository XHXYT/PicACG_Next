import { MainViewModel, mainVM } from '../viewmodel/MainViewModel';
import ComicCardScroll from './component/ComicCardScroll';
import ComicBanner from './component/ComicBanner';
import { PicState } from '../entryability/AppState';
import { ComicCardInterface } from '../common/Model';


@ComponentV2
export default struct Main {

  @Local viewModel: MainViewModel = mainVM;
  // 下拉刷新状态
  @Local isRefreshing: boolean = false;

  // 双击首页Tab触发的刷新信号（来自 mainVM.refreshTick）
  @Computed get refreshTick(): number {
    return this.viewModel.refreshTick
  }

  @Monitor('refreshTick')
  onRefreshTick() {
    this.triggerRefresh()
  }

  aboutToAppear(): void {
    // 触发数据加载
    this.viewModel.init();
  }

  build() {
    Refresh({ refreshing: this.isRefreshing }) {
      List() {
        // 排行榜-日榜-轮播图
        ListItem() {
          ComicBanner({
            attr: {
              type: 'remote',
              api: () => this.viewModel.fetchLeaderboard()
            },
            canSwipe: false,
            refreshTick: this.viewModel.refreshTick,
            onBannerItemClick: (comic) => {
              this.goDetail(comic)
            }
          })
        }
      // 随机本子区
      ListItem() {
        Column({ space: 5 }) {
          Column({ space: 7 }) {
            Text('随机本子')
              .width('100%')
            ComicCardScroll({
              comics: this.viewModel.random,
              onCardClick: (comic) => {
                this.goDetail(comic)
              }
            })
          }
        }
        .width('100%')
        .backgroundColor($r('app.color.start_window_background'))
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(HorizontalAlign.Center)
      }
      // 本子妹推荐区
      ListItem() {
        Column({ space: 5 }) {
          Column({ space: 7 }) {
            Text('本子妹推荐')
              .width('100%')
            ComicCardScroll({
              comics: this.viewModel.collections,
              onCardClick: (comic) => {
                this.goDetail(comic)
              }
            })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(HorizontalAlign.Center)
      }
      // 随机推荐区
      ListItem() {
        Column({ space: 5 }) {
          Column({ space: 7 }) {
            Text('随机推荐')
              .width('100%')
              .margin({ top: 3 })
            ComicCardScroll({
              comics: this.viewModel.recommend,
              onCardClick: (comic) => {
                this.goDetail(comic)
              }
            })
          }
        }
        .width('100%')
        .backgroundColor($r('app.color.start_window_background'))
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(HorizontalAlign.Center)
      }

      }
      .alignListItem(ListItemAlign.Start)
      .scrollBar(BarState.Off)
      .height('100%')
      .width('100%')
      .padding(10)
    }
    .onRefreshing(() => {
      this.triggerRefresh()
    })
    .backgroundColor($r('app.color.start_window_background'))
    .height('100%')
    .width('100%')
  }

  /**
   * 触发刷新（下拉/双击首页Tab共用），已在刷新中则忽略
   */
  private triggerRefresh() {
    if (this.isRefreshing) {
      return
    }
    this.isRefreshing = true
    this.doRefresh()
  }

  private async doRefresh() {
    const start = Date.now()
    try {
      await this.viewModel.init()
      // 通知轮播图重新加载
      this.viewModel.refreshTick++
    } finally {
      // 保证刷新动画至少展示 500ms，避免一闪而过
      const elapsed = Date.now() - start
      if (elapsed < 500) {
        await new Promise<void>((resolve) => setTimeout(resolve, 500 - elapsed))
      }
      this.isRefreshing = false
    }
  }

  private goDetail(comic: ComicCardInterface) {
    PicState.pageStack.pushPathByName('comic_detail', comic)
  }

}
