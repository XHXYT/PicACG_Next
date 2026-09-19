import { LogUtil } from '@pura/harmony-utils';
import { ComicDetailInfo, ComicSimpleInfo, SortType } from '../../api/models';
import { HistoryUtil } from '../../utils/History';
import { PreferenceManager } from '../../utils/preference/Settings';
import ComicListItem from './ComicListItem';
import { ToastUtil } from '../../utils/ToastUtils';
import { PicState } from '../../entryability/AppState';
import { ComicCardInterface, ComicListAttribute } from '../../common/Model';


@ObservedV2
class ComicListViewModel {
  @Trace comics: ComicDetailInfo[] = []; // 列表数据
  @Trace isRefreshing: boolean = false;
  @Trace isLoading: boolean = false;
  @Trace isEnd: boolean = false;

  private maxPage: number = 1;
  private total: number = 0;
  private page: number = 1;
  private attr: ComicListAttribute | null = null;

  // 初始化配置
  init(attr: ComicListAttribute) {
    this.attr = attr;
    this.page = 1;
    this.isEnd = false;
    this.maxPage = 1;
    this.refreshData();
  }

  // 刷新数据
  async refreshData() {
    this.page = 1;
    await this.loadData();
  }

  // 加载更多
  async loadMore() {
    if (this.isLoading || this.page >= this.maxPage) {
      return;
    }
    this.page++;
    await this.loadData();
  }

  // 统一加载逻辑
  private async loadData() {
    if (!this.attr) return;

    this.isLoading = true;

    try {
      if (this.attr.type === 'history') {
        await this.loadHistory();
      } else if (this.attr.type === 'reading') {
        await this.loadReading();
      } else if (this.attr.type === 'remote') {
        await this.loadRemote();
      }
    } catch (error) {
      LogUtil.error(`ComicList ViewModel load error: ${JSON.stringify(error)}`);
    } finally {
      ToastUtil.animateTo({ duration: 500 }, () => {
        this.isLoading = false;
        this.isRefreshing = false;
      });
    }
  }

  // 加载历史记录
  private async loadHistory() {
    ToastUtil.animateTo({ duration: 500 }, async () => {
      const res = await HistoryUtil.get();
      this.comics = res;
      LogUtil.debug(`加载浏览历史完成，总共：${this.comics.length}`);
    });
  }

  // 加载阅读记录
  private async loadReading() {
    ToastUtil.animateTo({ duration: 500 }, async () => {
      const res = await HistoryUtil.getReading();
      this.comics = res;
      LogUtil.debug(`加载阅读记录完成，总共：${this.comics.length}`);
    });
  }

  // 加载远程内容
  private async loadRemote() {
    if (!this.attr?.api) return;

    try {
      const res = await this.attr.api(this.page, this.attr.sort, this.attr.param1, this.attr.param2);

      ToastUtil.animateTo({ duration: 500 }, () => {
        if (this.page === 1) {
          this.comics = res.comics.docs;
        } else {
          // 数组解构赋值，@Trace会自动监听变化
          this.comics = [...this.comics, ...res.comics.docs];
        }
      });

      LogUtil.debug(`加载第${this.page}页，共${res.comics.docs.length}条`);
      this.page = res.comics.page;
      this.maxPage = res.comics.pages;
      this.total = res.comics.total;

    } catch (error) {
      LogUtil.error('Load remote failed');
    }
  }

  // 判断是否加载完毕
  isLoadEnd(): boolean {
    return this.comics.length === this.total;
  }
}


@ComponentV2
export default struct ComicList {
  @Param @Require attr: ComicListAttribute
  @Param canSwipe: boolean = true
  @Param showFilter: boolean = false
  @Param refreshTick: number = 0    // 刷新信号

  @Event deleteOperate?: (comic: ComicSimpleInfo, comics: ComicDetailInfo[]) => void
  @Event onItemClick: (comic: ComicCardInterface) => void

  @Local viewModel: ComicListViewModel = new ComicListViewModel();
  private scroll: Scroller = new Scroller()

  aboutToAppear(): void {
    // 初始化数据
    this.viewModel.init(this.attr);
  }

  // tick 变化时刷新数据
  @Monitor('refreshTick')
  onRefreshTickChange(): void {
    // 回到列表顶部，避免刷新后停在底部旧位置
    this.scroll.scrollTo({ xOffset: 0, yOffset: 0 })
    this.viewModel.refreshData()
  }

  build() {
    Column() {
      // 顶部筛选栏
      if (this.showFilter) {
        Scroll(new Scroller()) {
          Row() {
            ForEach(PicState.category, (cate: string, index: number) => {
              Button(cate)
                .height(30)
                .stateEffect(false)
                .margin({ left: index === 0 ? 0 : 5 })
                .backgroundColor(
                  PicState.filterCategory.indexOf(cate) >= 0 ? Color.Gray : $r('app.color.common_button_background_weight')
                )
                .onClick(() => {
                  if (PicState.filterCategory.indexOf(cate) >= 0) {
                    PicState.filterCategory = PicState.filterCategory.filter(c => c !== cate)
                  } else {
                    PicState.filterCategory.push(cate)
                  }
                })
            })
          }
          .height(40)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }

      // 下拉刷新组件
      Refresh({ refreshing: $$this.viewModel.isRefreshing }) {
        List({ space: 5, scroller: this.scroll }) {
          Repeat<ComicDetailInfo>(this.viewModel.comics)
            .key((item: ComicDetailInfo) => item._id) // 唯一标识
            .each((obj: RepeatItem<ComicDetailInfo>) => {
              ListItem() {
                ComicListItem({
                  image: `${PreferenceManager.image_api}${obj.item.thumb.path}`,
                  _id: obj.item._id,
                  title: obj.item.title,
                  pagesCount: obj.item.pagesCount,
                  finished: obj.item.finished,
                  author: obj.item.author,
                  categories: obj.item.categories,
                  likesCount: obj.item.totalLikes ? obj.item.totalLikes : obj.item.likesCount,
                  viewCount: obj.item.totalViews ? obj.item.totalViews : obj.item.viewsCount,
                  epsCount: obj.item.epsCount,
                  filter: this.showFilter,
                  onItemClick: (comic) => {
                    this.onItemClick(comic)
                  }
                })
              }
              .layoutWeight(1)
              .height(undefined)
              .borderRadius(30)
              .transition(TransitionEffect.asymmetric(
                TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 300 }),
                TransitionEffect.move(TransitionEdge.START).animation({ duration: 300 })
              ))
              // 滑动操作
              .swipeAction(this.canSwipe ? {
                end: {
                  builder: () => { this.itemEnd(obj.item) },
                  onAction: () => {
                    LogUtil.info('onAction:触发删除操作')
                    if (this.deleteOperate) {
                      // 注意：这里传递的是 viewModel 中的数据源
                      this.deleteOperate(obj.item, this.viewModel.comics)
                    }
                  },
                  actionAreaDistance: 56,
                }
              } : undefined)
            })
            // 启用虚拟滚动优化
            .virtualScroll({
              // 可以在此配置内存优化策略，例如：
              // memoryOptimizationStrategy: RepeatMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION
            })

          // 底部加载状态项
          if (this.viewModel.isLoadEnd()) {
            ListItem() {
              Row() { Text('没有更多了') }
              .width('100%')
              .height(64)
              .justifyContent(FlexAlign.Center)
            }
          }

          if (this.viewModel.isLoading) {
            ListItem() {
              Row() { LoadingProgress().height(32).width(48) }
              .width('100%')
              .height(64)
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: $r('app.color.custom_gray'), startMargin: 10, endMargin: 10 })
        .scrollBar(BarState.Off)
        .onScrollIndex((_: number, end: number) => {
          // 滚动到底部触发加载更多
          const isEnd = end + 5 >= this.viewModel.comics.length
          if (isEnd) {
            LogUtil.info('onReachEnd到底辣！！！要加载更多')
            this.viewModel.loadMore()
          }
        })
      }
      .onRefreshing(() => {
        LogUtil.info('刷新！！！！')
        this.viewModel.refreshData()
      })
      .layoutWeight(1)
      .refreshOffset(64)
      .pullToRefresh(true)
    }
    .layoutWeight(1)

  }

  @Builder itemEnd(comic: ComicSimpleInfo) {
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
      .onClick(() => {
        if (this.deleteOperate) {
          this.deleteOperate(comic, this.viewModel.comics)
        }
      })
    }
    .padding(4)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

}


