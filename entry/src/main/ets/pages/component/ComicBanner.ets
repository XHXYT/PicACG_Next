import { ComicDetailInfo } from '../../api/models';
import { ComicCardInterface, ComicListAttribute } from '../../common/Model';
import { ToastUtil } from '../../utils/ToastUtils';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { HomeBannerBannerMargin, HomeBannerDisplayCount } from '../../utils/breakpoint/BreakPoint';
import { PreferenceManager } from '../../utils/preference/Settings';
import { PicState } from '../../entryability/AppState';
import { createLogger } from '../../utils/Logger';

const logger = createLogger('ComicBanner')

// MVVM: ViewModel 层
@ObservedV2
class ComicBannerViewModel {
  @Trace comics: ComicDetailInfo[] = [];
  @Trace isLoading: boolean = false;
  @Trace isEnd: boolean = false;

  private page: number = 1;
  private maxPage: number = 1;
  private attr: ComicListAttribute | null = null;

  init(attr: ComicListAttribute) {
    this.attr = attr;
    this.loadComics();
  }

  loadComics() {
    logger.debug('Banner ViewModel 开始加载远程数据');
    this.loadRemote();
  }

  private async loadRemote() {
    if (!this.attr || !this.attr.api) return;
    this.isLoading = true;

    try {
      const res = await this.attr.api(this.page, this.attr.sort, this.attr.param1, this.attr.param2);
      ToastUtil.animateTo({ duration: 500 }, () => {
        this.comics = res.comics.docs;
      });
      logger.debug(`Banner ViewModel 加载第${this.page}页，共${res.comics.docs.length}条`);
      this.page = res.comics.page;
      this.maxPage = res.comics.pages;
    } catch (error) {
      logger.error(`Banner ViewModel 加载失败: ${JSON.stringify(error)}`);
    } finally {
      logger.debug('Banner ViewModel 加载远程数据结束');
      ToastUtil.animateTo({ duration: 500 }, () => {
        this.isLoading = false;
      });
    }
  }
}

@ComponentV2
export default struct ComicBanner {
  @Param @Require attr: ComicListAttribute
  @Param showFilter: boolean = false
  @Param canSwipe: boolean = true
  @Param refreshTick: number = 0    // 刷新信号：递增触发重新加载
  @Event onBannerItemClick: (comic: ComicCardInterface) => void

  @Local viewModel: ComicBannerViewModel = new ComicBannerViewModel();

  private scroll: SwiperController = new SwiperController()

  aboutToAppear() {
    this.viewModel.init(this.attr);
  }

  @Monitor('refreshTick')
  onRefreshTick() {
    this.viewModel.loadComics()
  }

  build() {
    // Swiper 容器
    Swiper(this.scroll) {
      Repeat<ComicDetailInfo>(this.viewModel.comics)
        .each((obj: RepeatItem<ComicDetailInfo>) => {
          this.BannerItem(obj.item)
        })
        // 配置虚拟滚动选项
        .virtualScroll({})
    }
    .loop(true)
    .width('100%')
    .itemSpace(9)
    .autoPlay(true)
    .interval(6000)
    .indicator(false)
    .prevMargin(HomeBannerBannerMargin(PicState.widthBp))
    .nextMargin(HomeBannerBannerMargin(PicState.widthBp))
    .displayCount(HomeBannerDisplayCount(PicState.widthBp))
    .cachedCount(2)
  }

  // 轮播图项 Builder
  @Builder
  BannerItem(comic: ComicDetailInfo) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Image(`${PreferenceManager.image_api}${comic.thumb.path}`)
        .layoutWeight(1)
        .borderRadius(16)
        .aspectRatio(1.75)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.loading'))
        .shadow({
          radius: 16,
          color: PicState.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#aaaaaa',
          offsetX: 6,
          offsetY: 6
        })

      Row()
        .width('100%')
        .borderRadius(16)
        .aspectRatio(1.75)
        .backgroundColor(PicState.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#80000000' : '#40000000')

      Text(comic.title)
        .fontColor(Color.White)
        .fontSize(16)
        .padding(12)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .alignSelf(ItemAlign.Start)
    }
    .padding({ top: 16, bottom: 16 })
    .foregroundBlurStyle(PreferenceManager.privacy_mode ? BlurStyle.Thin : BlurStyle.NONE)
    .onClick(() => {
      let comicCard: ComicCardInterface = {
        id: comic._id,
        image: `${PreferenceManager.image_api}${comic.thumb.path}`,
        title: comic.title
      }
      this.onBannerItemClick(comicCard)
    })
  }

}
