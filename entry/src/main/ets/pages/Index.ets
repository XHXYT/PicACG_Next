import { NavItem } from '../common/Types'
import Home from './view/Home'
import Main from './view/Main'
import Categories from './view/Categories'
import SearchHead from './component/SearchHead'
import { BusinessError } from '@ohos.base'
import { LogUtil } from '@pura/harmony-utils'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { compareVersions, extractUpdateInfo, getUpdateInfo, UpdateInfo } from '../utils/CheckUpdate'
import { getPackageInfo, PreferenceStorageKey } from '../utils/Preference'
import { TheCustomDialog } from './component/CustomDialog'
import { GoToWeb } from '../utils/GoWeb'
import { TabBarVertical, TabBarPosition } from '../utils/breakpoint/BreakPoint'
import { ToastUtil } from '../utils/ToastUtils'

@Entry
@Component
struct Index {

  @State currentTabIndex: number = 0
  @State refreshKeyword: boolean = false
  @StorageLink('VersionName') versionName: string = ''
  @StorageLink('WindowWidth') windowWidth: number = 0
  @StorageLink('WindowHeight') windowHeight: number = 0
  @StorageProp('topRectHeight') topRectHeight: number = 0
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('currentWidthBreakpoint') widthBp: WidthBreakpoint = 1;
  @StorageLink('currentHeightBreakpoint') heightBp: HeightBreakpoint = 0;

  @StorageLink('foregroundBlur') foregroundBlurMode: boolean = false
  // 自动更新变量
  @StorageLink(PreferenceStorageKey.AUTO_UPDATE) autoUpdate: boolean = false
  // 应用更新信息
  @Provide latestVersionInfo: UpdateInfo = {tag_name: this.versionName, name: '1.1.1', published_at: '2024-03-01T15:13:58Z', browser_download_url: ''}

  private context = this.getUIContext().getHostContext()! as common.UIAbilityContext
  // 检查更新弹窗控制器
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: TheCustomDialog({
      confirm: () => {
        GoToWeb(this.latestVersionInfo.browser_download_url, this.context)
        // 关闭背景模糊
        this.foregroundBlurMode = false
      },
      cancel: () => {
        // 关闭背景模糊
        this.foregroundBlurMode = false
      },
      title: `发现新版本${this.latestVersionInfo.tag_name}`,
      content: '发现新版本，是否前往更新',
      rightText: '前往更新'
    }),
    autoCancel: false,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {

      } else if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {

      } else {
        // 关闭背景模糊
        this.foregroundBlurMode = false
        dismissDialogAction.dismiss()
      }
    }
  })
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack()
  // Tab控制器
  private tabController: TabsController = new TabsController()
  // Tab页
  private navItem: NavItem[] = [
    new NavItem(0, $r('sys.symbol.house_fill'), '首页'),
    new NavItem(1, $r('sys.symbol.square_fill_grid_2x2'), '分类'),
    new NavItem(2, $r('sys.symbol.person'), '我的')
  ]

  build() {
    Navigation(this.pageStack) {
      Column() {
        SearchHead({ refreshKeyword: this.refreshKeyword })
          .width('100%')
          .height(50)
        Tabs({
          index: this.currentTabIndex,
          barPosition: TabBarPosition(this.widthBp, this.heightBp),
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
        .vertical(TabBarVertical(this.widthBp, this.heightBp))
        .barMode(BarMode.Fixed)
        .onTabBarClick((index: number) => {
          ToastUtil.animateTo({
            duration: 300,
            curve: Curve.Linear,
          }, () => {
            this.currentTabIndex = index
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
      .padding({ top: this.topRectHeight, bottom: this.bottomRectHeight - 10 })
    }.hideToolBar(true)
    .mode(NavigationMode.Stack)
    .foregroundBlurStyle(this.foregroundBlurMode ? BlurStyle.Thin : BlurStyle.NONE)
    .onNavBarStateChange((isVisible) => {
      // 刷新顶部搜索框关键词
      if (isVisible) {
        this.refreshKeyword = !this.refreshKeyword
      }
    })
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
  }

  async aboutToAppear(): Promise<void> {
    // 查询版本号
    const packageInfo = await getPackageInfo()
    this.versionName = packageInfo.versionName
    // 自动检查更新
    if (this.autoUpdate) {
      // 检查版本更新
      try {
        const updateInfo = await getUpdateInfo()
        hilog.info(0xFF00, "UpdatetestTag", "Update Info: %{public}s", JSON.stringify(updateInfo))
        const theLatest = extractUpdateInfo(updateInfo)
        if (theLatest) {
          // 查询完成
          if (compareVersions(theLatest.tag_name, this.versionName)) {
            this.latestVersionInfo = theLatest
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