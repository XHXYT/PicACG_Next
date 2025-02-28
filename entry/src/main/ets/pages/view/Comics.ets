import { LogUtil, ObjectUtil } from '@pura/harmony-utils'
import {
  ComicResponse,
  comicsByAuthor,
  comicsByCategory,
  comicsByTeam,
  comicsByUploader,
  random,
  search
} from '../../api/comic'
import { SortType } from '../../api/models'
import { SortItems } from '../../common/Config'
import { PreferenceItem } from '../../utils/Preference'
import ComicList, { ComicListAttribute } from '../component/ComicList'
import { BackType, TitleBar, TitleType } from '../component/TitleBar'
import { SymbolGlyphModifier } from '@kit.ArkUI'
import { StorageKey } from '../../common/Consts'
import HalfModal from '../component/HalfModal'

@Builder
export function ComicsBuilder(name: string, param: Object) {
  Comics()
}

@Component
export default struct Comics {
  // 状态栏高度
  @StorageProp('topRectHeight') topRectHeight: number = 0
  // 导航栏高度
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  // 背景模糊
  @StorageLink('foregroundBlur') foregroundBlurMode: boolean = false
  @StorageLink(StorageKey.CATEGORY) category: string[] = []
  @Consume('pageStack') pageStack: NavPathStack
  @State searchParam: ComicListOptions | undefined = undefined
  @State attr: ComicListAttribute | undefined = undefined
  @State @Watch('sortChange') sort: SortType = SortType.Newest
  @State @Watch('categoryChange') filterCategory: string[] = []
  @State showCategory: boolean = false
  @State tempSelectedCategory: string[] = []

  sortChange() {
    this.buildAttr()
  }

  categoryChange() {
    this.buildAttr()
  }

  buildAttr() {
    if (this.searchParam?.type === SearchType.Custom) {
      // 关键字查询
      this.attr = {
        type: 'remote',
        api: search as (page?: number, s?: SortType, p3?: string, p4?: string | string[]) => Promise<ComicResponse>,
        sort: this.sort,
        param1: this.searchParam.key,
        param2: this.filterCategory
      }
    } else if (this.searchParam?.type === SearchType.Category) {
      // 分类查询
      LogUtil.info('分类查询：', this.searchParam.key)
      this.attr = {
        type: 'remote',
        api: comicsByCategory as (page?: number, s?: SortType, p3?: string) => Promise<ComicResponse>,
        sort: this.sort,
        param1: this.searchParam.key,
      }
    } else if (this.searchParam?.type === SearchType.Uploader) {
      // Uploader查询
      LogUtil.info('Uploader查询：', this.searchParam.key)
      this.attr = {
        type: 'remote',
        api: comicsByUploader as (page?: number, s?: SortType, p3?: string) => Promise<ComicResponse>,
        sort: this.sort,
        param1: this.searchParam.key,
      }
    } else if (this.searchParam?.type === SearchType.Author) {
      // Author查询
      LogUtil.info('Author查询：', this.searchParam.key)
      this.attr = {
        type: 'remote',
        api: comicsByAuthor as (page?: number, s?: SortType, p3?: string) => Promise<ComicResponse>,
        sort: this.sort,
        param1: this.searchParam.key,
      }
    } else if (this.searchParam?.type === SearchType.Team) {
      // Team查询
      LogUtil.info('Team查询：', this.searchParam.key)
      this.attr = {
        type: 'remote',
        api: comicsByTeam as (page?: number, s?: SortType, p3?: string) => Promise<ComicResponse>,
        sort: this.sort,
        param1: this.searchParam.key,
      }
    } else {
      // 随机查询
      this.attr = {
        type: 'remote',
        api: (): Promise<ComicResponse> => {
          return new Promise<ComicResponse>((resolve, reject) => {
            random().then(res => {
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
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 标题栏
        TitleBar({
          titleBarColor: $r('app.color.start_window_background'),
          statusBarColor: $r('app.color.start_window_background'),
          centerType: TitleType.TEXT,
          centerText: this.searchParam?.title ? this.searchParam?.title : this.searchParam?.key,
          centerTextColor: $r('app.color.common_button_background_light'),
          leftImageHeight: 28,
          leftBackType: BackType.NONE,
          leftBackFillColor: $r('app.color.common_button_background_light'),
          leftOnClick: () => {
            this.pageStack.pop()
          },
          rightType: TitleType.CUSTOM,
          rightCustomView: () => {
            this.rightBuilder()
          },
          titleBarRightPadding: 0
        })
        // 漫画列表
        ComicList({ attr: this.attr, canSwipe: false, showFilter: true })
      }
      .height('100%')
      .width('100%')
      .padding({
        left: 10,
        right: 10,
        top: this.topRectHeight
      })

      HalfModal({
        show: this.showCategory,
        view: () => {
          this.categoryFilter()
        },
        options: {
          title: {
            title: '限定分类',
          },
          height: SheetSize.FIT_CONTENT,
          showClose: false,
          dragBar: false,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          onDisappear: () => {
            this.showCategory = false
          },
        }
      })
    }.hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
    .backgroundColor($r('app.color.start_window_background'))
    .onReady((context: NavDestinationContext) => {
      this.searchParam = context.pathInfo.param as ComicListOptions
      this.buildAttr()
    })
  }

  @Builder
  categoryFilter() {
    Column() {
      GridRow() {
        ForEach(this.category, (key: string) => {
          GridCol({
            span: 6
          }) {
            Row() {
              Checkbox({ name: key, group: 'checkboxGroup' })
                .select(this.tempSelectedCategory.indexOf(key) >= 0)
                .selectedColor($r('app.color.custom_pink'))
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .onChange((selected: boolean) => {
                  if (selected) {
                    this.tempSelectedCategory.push(key)
                  } else {
                    this.tempSelectedCategory = this.tempSelectedCategory.filter(k => k !== key)
                  }
                })
                .mark({
                  size: 50,
                  strokeWidth: 5
                })
                .width(20)
                .height(20)
              Text(key)
                .fontSize(16)
                .onClick(() => {
                  LogUtil.info('onClick')
                  if (this.tempSelectedCategory.indexOf(key) < 0) {
                    LogUtil.info('selected: ', key)
                    this.tempSelectedCategory.push(key)
                  } else {
                    LogUtil.info('unselected: ', key)
                    this.tempSelectedCategory = this.tempSelectedCategory.filter(k => k !== key)
                  }
                })
            }
            .width('100%')
          }
        })
      }
      .margin({ bottom: 20 })

      Button('确认搜索')
        .width('100%')
        .stateEffect(false)
        .type(ButtonType.Normal)
        .borderRadius(10)
        .backgroundColor($r('app.color.common_button_background_light'))
        .clickEffect({ level: ClickEffectLevel.LIGHT })
        .onClick(() => {
          animateTo({ duration: 500 }, () => {
            this.showCategory = false
            this.filterCategory = ObjectUtil.deepCopy(this.tempSelectedCategory)
          })
        })
    }.width('100%')
    .margin({ bottom: this.bottomRectHeight })
    .padding({ left: 20, right: 20 })
  }

  /**
   * 排序菜单
   */
  @Builder
  sortMenu() {
    Menu() {
      ForEach(SortItems, ((item: PreferenceItem) => {
        MenuItem({
          symbolEndIcon: new SymbolGlyphModifier(item.icon as Resource)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor([$r('app.color.common_button_background_light')]),
          content: item.name,
        })
          .contentFont({ size: 16 })
          .selected(this.sort === item.value)
          .selectIcon(new SymbolGlyphModifier($r('sys.symbol.checkmark'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor([$r('app.color.common_button_background_light')])
          )
          .onChange(selected => {
            if (selected) {
              this.sort = SortType[item.key]
            }
          })
      }))

    }
  }

  /**
   * 右侧自定义视图
   */
  @Builder
  rightBuilder() {
    Row({space: 10}) {
      // 排序
      SymbolGlyph($r('sys.symbol.sort'))
        .fontColor([$r('app.color.common_button_background_light')])
        .bindMenu(this.sortMenu)
        .fontSize(21)
      // 分类
      SymbolGlyph($r('sys.symbol.square_grid_2x2'))
        .visibility(this.searchParam?.type === SearchType.Custom ? Visibility.Visible : Visibility.None)
        .enabled(!this.showCategory)
        .fontColor([$r('app.color.common_button_background_light')])
        .fontSize(21)
        .onClick(() => {
          LogUtil.info('category: ', this.category.toString())
          this.showCategory = true
        })
      // 搜索
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontColor([$r('app.color.common_button_background_light')])
        .fontSize(23)
        .onClick(() => {
          this.pageStack.pushPath({ name: 'ComicSearch' })
        })
    }
  }
}

export interface ComicListOptions {
  type: SearchType
  title?: string
  key?: string
}

export enum SearchType {
  Random,
  Category,
  Custom,
  Uploader,
  Author,
  Team
}