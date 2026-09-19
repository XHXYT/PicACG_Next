import { NavItem } from '../common/Types'
import Home from './Home'
import Main from './Main'
import Categories from './view/Categories'
import SearchHead from './component/SearchHead'
import { BusinessError } from '@ohos.base'
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
        // 关闭背景模糊
        PicState.foregroundBlurMode = false
      },
      cancel: () => {
        // 关闭背景模糊
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
        // 关闭背景模糊
        PicState.foregroundBlurMode = false
        dismissDialogAction.dismiss()
      }
    }
  })
  // Tab控制器
  private tabController: TabsController = new TabsController()
  // Tab页
  private navItem: NavItem[] = [
    new NavItem(0, $r('sys.symbol.house_fill'), '首页'),
    new NavItem(1, $r('sys.symbol.square_fill_grid_2x2'), '分类'),
    new NavItem(2, $r('sys.symbol.person'), '我的')
  ]

  build() {
    if (PicState.token) {
      Navigation(PicState.pageStack) {
        Column() {
          SearchHead({ refreshKeyword: this.refreshKeyword })
            .width('100%')
            .height(50)
          Tabs({
            index: this.currentTabIndex,
            barPosition: TabBarPosition(PicState.widthBp, PicState.heightBp),
            controller: this.tabController
          }) {
            ForEach(this.navItem, (item: NavItem) => {
              TabContent() {
                if (item.index === 0) {
                  Main()
                } else if (item.index === 1) {
                  Categories()
                } else if (item.index === 2) {
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
            ToastUtil.animateTo({
              duration: 300,
              curve: Curve.Linear,
            }, () => {
              this.currentTabIndex = index
              // 切到"我的"页时刷新
              if (index === 2) {
                homeVM.loadProfile()   // 顺带刷新用户信息/签到状态
                homeVM.consumeDirtyAt(homeVM.currentSubIndex)  // 按脏标记刷新当前子列表
              }
            })
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
        .padding({ top: PicState.topRectHeight, bottom: PicState.bottomRectHeight - 10 })
      }.hideToolBar(true)
      .mode(NavigationMode.Stack)
      .foregroundBlurStyle(PicState.foregroundBlurMode ? BlurStyle.Thin : BlurStyle.NONE)
      .onNavBarStateChange((isVisible) => {
        // 刷新顶部搜索框关键词
        if (isVisible) {
          this.refreshKeyword = !this.refreshKeyword
          // 从二级页面返回"我的"页时，按脏标记刷新当前子列表
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
  TabBuilder(navItem: NavItem) {
    Column({space: 2}) {
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center
      }) {
        SymbolGlyph(navItem.tabIcons)
          .fontColor([this.currentTabIndex === navItem.index ? $r('app.color.common_button_background_light') : Color.Gray])
            // 分层颜色
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
    // 双击"首页"Tab 触发首页刷新（单击切换 Tab 不受影响）
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
    // 查询版本号
    const packageInfo = await getPackageInfo()
    PicState.appVersion = packageInfo.versionName
    // 自动检查更新
    if (PreferenceManager.auto_update) {
      // 检查版本更新
      try {
        const updateInfo = await getUpdateInfo()
        hilog.info(0xFF00, "UpdatetestTag", "Update Info: %{public}s", JSON.stringify(updateInfo))
        const theLatest = extractUpdateInfo(updateInfo)
        if (theLatest) {
          // 查询完成
          if (compareVersions(theLatest.tag_name, PicState.appVersion)) {
            PicState.latestVersionInfo = theLatest
            // 前往更新
            this.dialogController.open()
          }
        } else {
          hilog.info(0xFF00, "UpdatetestTag", "获取更新信息失败")
        }
      } catch (err) {
        // 处理错误情况
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