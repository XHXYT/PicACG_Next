import { NavItem } from '../common/Types'
import Home from './Home'
import Main from './Main'
import Categories from './view/Categories'
import SearchHead from './component/SearchHead'
import { LengthUnit } from '@kit.ArkUI'
import { LogUtil } from '@pura/harmony-utils'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { compareVersions, extractUpdateInfo, getUpdateInfo } from '../utils/CheckUpdate'
import { getPackageInfo, PreferenceManager } from '../utils/preference/Settings'
import { TheCustomDialog } from './component/CustomDialog'
import { GoToWeb } from '../utils/GoWeb'
import { TabBarVertical, TabBarPosition } from '../utils/breakpoint/BreakPoint'
import { ToastUtil } from '../utils/ToastUtils'
import { PicState, _PicState } from '../entryability/AppState'
import { Login } from './Login'
import { homeVM } from '../viewmodel/HomeViewModel'
import { mainVM } from '../viewmodel/MainViewModel'


@Entry
@ComponentV2
struct Index {

  @Local currentTabIndex: number = 0
  @Local refreshKeyword: boolean = false

  // 检查更新弹窗控制器
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: TheCustomDialog({
      confirm: () => {
        GoToWeb(PicState.latestVersionInfo.browser_download_url, _PicState.Context)
        PicState.foregroundBlurMode = false
      },
      cancel: () => {
        PicState.foregroundBlurMode = false
      },
      title: `发现新版本${PicState.latestVersionInfo.tag_name}`,
      content: '发现新版本，是否前往更新',
      rightText: '前往更新'
    }),
    autoCancel: false,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
      } else if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
      } else {
        PicState.foregroundBlurMode = false
        dismissDialogAction.dismiss()
      }
    }
  })
  // Tab页
  private navItem: NavItem[] = [
    new NavItem(0, $r('sys.symbol.house_fill'), '首页'),
    new NavItem(1, $r('sys.symbol.square_fill_grid_2x2'), '分类'),
    new NavItem(2, $r('sys.symbol.person'), '我的')
  ]

  build() {
    if (PicState.token) {
      Navigation(PicState.pageStack) {
        if (PicState.windowMode) {
          this.PCLayout()
        } else {
          this.MobileLayout()
        }
      }.hideToolBar(true)
      .mode(NavigationMode.Stack)
      .foregroundBlurStyle(PicState.foregroundBlurMode ? BlurStyle.Thin : BlurStyle.NONE)
      .onNavBarStateChange((isVisible) => {
        if (isVisible) {
          this.refreshKeyword = !this.refreshKeyword
          if (this.currentTabIndex === 2) {
            homeVM.consumeDirtyAt(homeVM.currentSubIndex)
          }
        }
      })
    } else {
      Login()
    }
  }

  @Builder
  PCLayout() {
    Row() {
      // 左侧边栏
      Column() {
        Text('PicACG')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.common_button_background_light'))
          .height(50)
          .width('100%')
          .padding({ left: 24 })
          .align(Alignment.Start)

        ForEach(this.navItem, (item: NavItem) => {
          Row({ space: 12 }) {
            SymbolGlyph(item.tabIcons)
              .fontColor([this.currentTabIndex === item.index
                ? $r('app.color.common_button_background_light') : Color.Gray])
            Text(item.title)
              .fontSize(15)
              .fontColor(this.currentTabIndex === item.index
                ? $r('app.color.common_button_background_light') : Color.Gray)
          }
          .width('100%')
          .height(48)
          .padding({ left: 24 })
          .borderRadius(8)
          .backgroundColor(this.currentTabIndex === item.index
            ? 'rgba(255, 107, 107, 0.15)' : Color.Transparent)
          .clickEffect({ level: ClickEffectLevel.LIGHT })
          .onClick(() => {
            this.switchTab(item.index)
          })
          .gesture(
            TapGesture({ count: 2 })
              .onAction(() => {
                if (item.index === 0) {
                  mainVM.requestRefresh()
                }
              })
          )
        }, (item: NavItem) => item.index.toString())
      }
      .width('220vp')
      .height('100%')
      .padding({ top: '8vp', left: '12vp', right: '12vp' })
      .backgroundColor($r('app.color.start_window_background'))
      .borderWidth({ end: { value: 1, unit: LengthUnit.VP } })
      .borderColor($r('app.color.custom_gray'))

      // 内容区：所有页面常驻，用显隐控制切换（永不销毁重建）
      Column() {
        SearchHead({ refreshKeyword: this.refreshKeyword })
          .width('100%')
          .height(50)
          .padding({ right: PicState.rightAvoidWidth })
        Stack() {
          Main()
            .visibility(this.currentTabIndex === 0 ? Visibility.Visible : Visibility.None)
          Categories()
            .visibility(this.currentTabIndex === 1 ? Visibility.Visible : Visibility.None)
          Home()
            .visibility(this.currentTabIndex === 2 ? Visibility.Visible : Visibility.None)
        }
        .layoutWeight(1)
        .width('100%')
      }
      .layoutWeight(1)
      .height('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('app.color.start_window_background'))
    .padding({ top: PicState.topRectHeight, bottom: PicState.bottomRectHeight - 10 })
  }

  @Builder
  MobileLayout() {
    Column() {
      SearchHead({ refreshKeyword: this.refreshKeyword })
        .width('100%')
        .height(50)
      Tabs({
        index: this.currentTabIndex,
        barPosition: TabBarPosition(PicState.widthBp, PicState.heightBp),
        controller: new TabsController()
      }) {
        ForEach(this.navItem, (item: NavItem) => {
          TabContent() {
            if (item.index === 0) {
              Main()
            } else if (item.index === 1) {
              Categories()
            } else {
              Home()
            }
          }
          .tabBar(this.TabBuilder(item))
        })
      }
      .layoutWeight(1)
      .vertical(TabBarVertical(PicState.widthBp, PicState.heightBp))
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.switchTab(index)
      })
      .onAppear(() => {
        LogUtil.info('Tabs ready')
      })
    }.height('100%').width('100%')
    .backgroundColor($r('app.color.start_window_background'))
    .padding({ top: PicState.topRectHeight, bottom: PicState.bottomRectHeight - 10 })
  }

  switchTab(index: number): void {
    this.currentTabIndex = index
    if (index === 2) {
      homeVM.loadProfile()
      homeVM.consumeDirtyAt(homeVM.currentSubIndex)
    }
  }

  @Builder
  TabBuilder(navItem: NavItem) {
    Column({ space: 2 }) {
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center
      }) {
        SymbolGlyph(navItem.tabIcons)
          .fontColor([this.currentTabIndex === navItem.index
            ? $r('app.color.common_button_background_light') : Color.Gray])
          .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_OPACITY)
          .fontSize(25)
        Text(navItem.title)
          .fontSize(12)
          .margin(5)
          .fontColor(this.currentTabIndex === navItem.index
            ? $r('app.color.common_button_background_light') : Color.Gray)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.start_window_background'))
    .gesture(
      TapGesture({ count: 2 })
        .onAction(() => {
          if (navItem.index === 0) {
            mainVM.requestRefresh()
          }
        })
    )
  }

  async aboutToAppear(): Promise<void> {
    const packageInfo = await getPackageInfo()
    PicState.appVersion = packageInfo.versionName
    if (PreferenceManager.auto_update) {
      try {
        const updateInfo = await getUpdateInfo()
        hilog.info(0xFF00, "UpdatetestTag", "Update Info: %{public}s", JSON.stringify(updateInfo))
        const theLatest = extractUpdateInfo(updateInfo)
        if (theLatest) {
          if (compareVersions(theLatest.tag_name, PicState.appVersion)) {
            PicState.latestVersionInfo = theLatest
            this.dialogController.open()
          }
        } else {
          hilog.info(0xFF00, "UpdatetestTag", "获取更新信息失败")
        }
      } catch (err) {
        const infoError = `Error:${JSON.stringify(err)}`
        hilog.info(0xFF00, "UpdatetestTag", "Info: %{public}s", infoError)
      }
    }
  }

  onPageShow(): void {
  }

  aboutToDisappear(): void {
  }

}