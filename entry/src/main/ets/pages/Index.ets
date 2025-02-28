import { NavItem } from '../common/Types'
import Home from './view/Home'
import Main from './view/Main'
import Categories from './view/Categories'
import SearchHead from './component/SearchHead'
import { BusinessError } from '@ohos.base'
import { LogUtil } from '@pura/harmony-utils'
import { BreakpointState, BreakpointSystem } from '../utils/BreakPoint'
import { CompStr, TabVertical } from '../common/BreakPoint'
import { deviceInfo } from '@kit.BasicServicesKit'

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0
  @State refreshKeyword: boolean = false
  @StorageProp('topRectHeight') topRectHeight: number = 0
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack()
  @StorageLink('foregroundBlur') foregroundBlurMode: boolean = false
  // 断点
  @Provide('CompStr') compStr: BreakpointState<string> = CompStr
  // tab栏模式
  @Provide('TabVertical') compVertical: BreakpointState<boolean> = TabVertical


  tabController: TabsController = new TabsController()

  navItem: NavItem[] = [
    new NavItem(0, $r('sys.symbol.house_fill'), '首页'),
    new NavItem(1, $r('sys.symbol.square_fill_grid_2x2'), '分类'),
    new NavItem(2, $r('sys.symbol.person'), '我的')
  ]

  @Builder
  TabBuilder(navItem: NavItem) {
    Column({space: 2}) {
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center
      }) {
        SymbolGlyph(navItem.tabIcons)
          .fontColor([this.currentTabIndex === navItem.index ? $r('app.color.common_button_background_light') : Color.Gray])
            //分层颜色
          .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_OPACITY)
          .fontSize(25)
        Text(navItem.title)
          .fontSize(12)
          .margin(5)
          .fontColor(this.currentTabIndex === navItem.index ? $r('app.color.common_button_background_light') : Color.Gray)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.start_window_background'))
  }

  build() {
    Navigation(this.pageStack) {
      Column() {
        SearchHead({ refreshKeyword: this.refreshKeyword })
          .width('100%')
          .height(50)

        Tabs({
          index: this.currentTabIndex,
          barPosition: this.compVertical.value ? BarPosition.Start : BarPosition.End,
          controller: this.tabController
        }) {
          ForEach(this.navItem, (item: NavItem) => {
            TabContent() {
              Column() {
                if (item.index === 0) {
                  Main()
                } else if (item.index === 1) {
                  Categories()
                } else if (item.index === 2) {
                  Home()
                }
              }
            }
            .tabBar(this.TabBuilder(item))
          })
        }
        .layoutWeight(1)
        .vertical((deviceInfo.deviceType === 'phone' && this.compStr.value === 'md') ? true : this.compVertical.value)
        .barMode(BarMode.Fixed)
        .onChange((index) => {
          this.currentTabIndex = index
        })
        .onAppear(() => {
          this.tabController.preloadItems([0, 1, 2])
            .then(() => {
              LogUtil.info('preloadItems success.')
            })
            .catch((error: BusinessError) => {
              LogUtil.error('preloadItems failed, error code: ' + error.code + ', error message: ' + error.message)
            })
        })
      }.height('100%').width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ top: this.topRectHeight, bottom: this.bottomRectHeight - 20 })
      .foregroundBlurStyle(this.foregroundBlurMode ? BlurStyle.Thin : BlurStyle.NONE)
    }.hideToolBar(true)
    .mode(NavigationMode.Stack)
    .onNavBarStateChange((isVisible) => {
      // 刷新顶部搜索框关键词
      if (isVisible) {
        this.refreshKeyword = !this.refreshKeyword
      }
    })
  }

  aboutToAppear(): void {
    // 启用监听断点事件
    BreakpointSystem.getInstance().start()
    BreakpointSystem.getInstance().attach(this.compStr)
    BreakpointSystem.getInstance().attach(this.compVertical)
    LogUtil.info('断点为：' + this.compStr.value)
  }

  aboutToDisappear(): void {
    // 停止监听断点事件，并清空断点对应数据
    BreakpointSystem.getInstance().stop()
  }

}