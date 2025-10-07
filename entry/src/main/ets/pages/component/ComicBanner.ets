import { LogUtil } from '@pura/harmony-utils';
import { ComicDetailInfo } from '../../api/models';
import { StorageKey } from '../../common/Consts';
import { PreferenceStorageKey } from '../../utils/Preference';
import { ComicCardInterface } from './ComicCard';
import { ToastUtil } from '../../utils/ToastUtils';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { BaseDataSource } from '../../common/BaseDataSource';
import { HomeBannerBannerMargin, HomeBannerDisplayCount } from '../../utils/breakpoint/BreakPoint';
import { ComicListAttribute } from './ComicList';

@Component
export default struct ComicBanner {

  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
  @StorageProp(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
  @StorageProp(StorageKey.CATEGORY) category: string[] = []
  @StorageLink(StorageKey.FILTER_CATEGORY) filterCategory: string[] = []
  @StorageLink('currentWidthBreakpoint') widthBp: WidthBreakpoint = 1;
  @StorageLink('currentHeightBreakpoint') heightBp: HeightBreakpoint = 0;
  @Consume('pageStack') pageStack: NavPathStack
  @Prop showFilter: boolean = false
  @State isLoading: boolean = false;
  @Prop canSwipe: boolean = true
  @State isEnd: boolean = false;
  @State maxPage: number = 1
  @State total: number = 0
  @State page: number = 1
  @Prop attr: ComicListAttribute

  @State comics: BannerDataSource = new BannerDataSource([])
  private scroll: SwiperController = new SwiperController()

  aboutToAppear() {
    this.loadComics()
  }

  build() {
    Swiper() {
      LazyForEach(this.comics, (item: ComicDetailInfo) => {
        this.BannerItem(item)
      }, (item: ComicDetailInfo) => item.created_at)
    }.loop(true)
    .width('100%')
    .itemSpace(9)
    .autoPlay(true)
    .interval(6000)
    .indicator(false)
    .prevMargin(HomeBannerBannerMargin(this.widthBp))
    .nextMargin(HomeBannerBannerMargin(this.widthBp))
    .displayCount(HomeBannerDisplayCount(this.widthBp))
  }

  // 轮播图项
  @Builder BannerItem(comic: ComicDetailInfo) {
    Stack({ alignContent: Alignment.BottomStart }) {
      // 封面
      Image(`${this.imageApi}${comic.thumb.path}`)
        .layoutWeight(1)
        .borderRadius(16)
        .aspectRatio(1.75)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.loading')) // 占位图
        .shadow({ radius: 16, color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#aaaaaa', offsetX: 6, offsetY: 6 })
      // 遮罩
      Row()
        .width('100%')
        .borderRadius(16)
        .aspectRatio(1.75)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#80000000' : '#40000000')
      // 标题
      Text(comic.title)
        .fontColor(Color.White)
        .fontSize(16)
        .padding(12)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .alignSelf(ItemAlign.Start)
    }
    .padding({ top: 16, bottom: 16 })
    .foregroundBlurStyle(this.privacyMode ? BlurStyle.Thin : BlurStyle.NONE)
    .onClick(() => {
      let comics: ComicCardInterface = {
        id: comic._id,
        image: `${this.imageApi}${comic.thumb.path}`,
        title: comic.title
      }
      this.pageStack.pushPathByName('ComicDetail', comics)
    })
  }

  loadComics() {
    LogUtil.debug('Banner 加载远程数据')
    this.loadRemote()
  }

  loadRemote() {
    if (this.attr.api !== undefined) {
      this.attr.api(this.page, this.attr.sort, this.attr.param1, this.attr.param2)
        .then((res) => {
          ToastUtil.animateTo({ duration: 500 }, () => {
            this.comics.pushData(res.comics.docs)
          })
          LogUtil.debug(`Banner 加载第${this.page}页，共${res.comics.docs.length}条`)
          this.page = res.comics.page
          this.maxPage = res.comics.pages
          this.total = res.comics.total
        })
        .finally(() => {
          LogUtil.debug('Banner 加载远程数据结束')
          ToastUtil.animateTo({ duration: 500 }, () => {
            this.isLoading = false
          })
        })
    }
  }

}

class BannerDataSource extends BaseDataSource<ComicDetailInfo> {
  private dataArray: ComicDetailInfo[] = []

  public totalCount(): number {
    return this.dataArray.length
  }

  public getData(index: number): ComicDetailInfo {
    return this.dataArray[index]
  }

  public addData(index: number, data: ComicDetailInfo): void {
    this.dataArray.splice(index, 0, data)
    this.notifyDataAdd(index)
  }

  public pushData(data: ComicDetailInfo[]): void {
    this.dataArray = data
    console.log(`Banner 推送数据：${data.length}个，总共：${this.dataArray.length}个`)
    this.notifyDataAdd(this.dataArray.length - 1)
  }

  // 删除全部数据
  public clear(): void {
    this.empty()
    this.refresh()
  }

  public empty(): void {
    this.dataArray = []
  }
  public refresh(): void {
    this.notifyDataReload()
  }
}
