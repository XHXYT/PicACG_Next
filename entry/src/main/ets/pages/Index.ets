import { NavItem } from '../common/Types'
import Home from './view/Home'
import Main from './view/Main'
import Categories from './view/Categories'
import SearchHead from './component/SearchHead'
import { BusinessError } from '@ohos.base'
import { LogUtil } from '@pura/harmony-utils'
import { BreakpointState, BreakpointSystem } from '../utils/BreakPoint'
import { CompStr, LoginImageHeight, MainEndOffset,
  MainLeaderboardHeight,
  MainPageColumnsTemplate, TabVertical } from '../common/BreakPoint'
import { deviceInfo } from '@kit.BasicServicesKit'
import { window } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { compareVersions, extractUpdateInfo, getUpdateInfo, UpdateInfo } from '../utils/CheckUpdate'
import { getPackageInfo, PreferenceStorageKey } from '../utils/Preference'
import { TheCustomDialog } from './component/CustomDialog'
import { GoToWeb } from '../utils/GoWeb'

const context = getContext(this) as common.UIAbilityContext

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
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack()
  @StorageLink('foregroundBlur') foregroundBlurMode: boolean = false
  // 断点
  @Provide('CompStr')@Watch('onWindowChange') compStr: BreakpointState<string> = CompStr
  // tab栏模式
  @Provide('TabVertical') compVertical: BreakpointState<boolean> = TabVertical
  // 首页底部偏移量
  @Provide('MainEndOffset') mainEndOffset: BreakpointState<number> = MainEndOffset
  // 首页排行榜高度
  @Provide('MainLeaderboardHeight') mainLeaderboardHeight: BreakpointState<number> = MainLeaderboardHeight
  // 首页Grid列数
  @Provide('MainPageColumnsTemplate') mainPageColumnsTemplate: BreakpointState<string> = MainPageColumnsTemplate
  // 自动更新变量
  @StorageLink(PreferenceStorageKey.AUTO_UPDATE) autoUpdate: boolean = false
  // 应用更新信息
  @Provide latestVersionInfo: UpdateInfo = {tag_name: this.versionName, name: '1.1.1', published_at: '2024-03-01T15:13:58Z', browser_download_url: ''}

  tabController: TabsController = new TabsController()

  navItem: NavItem[] = [
    new NavItem(0, $r('sys.symbol.house_fill'), '首页'),
    new NavItem(1, $r('sys.symbol.square_fill_grid_2x2'), '分类'),
    new NavItem(2, $r('sys.symbol.person'), '我的')
  ]

  onWindowChange() {
    let windowClass: window.Window | undefined = undefined
    try {
      let promise = window.getLastWindow(context)
      promise.then((data)=> {
        // 获取窗口对象
        windowClass = data
        try {
          // 获取窗口属性
          let properties = windowClass.getWindowProperties()
          let rect = properties.windowRect
          // 更新保存窗口宽度和高度
          this.windowWidth = px2vp(rect.width)
          this.windowHeight = px2vp(rect.height)
          hilog.info(0x0000, 'PicaWindowLog', '窗口新高度：%{public}d 新宽度：%{public}i', this.windowWidth, this.windowHeight)
        } catch (exception) {
          console.error('Failed to obtain the window properties. Cause: ' + JSON.stringify(exception));
        }
        console.info('Succeeded in obtaining the top window. Data: ' + JSON.stringify(data));
      }).catch((err: BusinessError)=>{
        console.error('Failed to obtain the top window. Cause: ' + JSON.stringify(err));
      });} catch (exception) {
      console.error('Failed to obtain the top window. Cause: ' + JSON.stringify(exception));
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
  }

  // 检查更新弹窗控制器
  dialogController: CustomDialogController = new CustomDialogController({
    builder: TheCustomDialog({
      confirm: () => {
        GoToWeb(this.latestVersionInfo.browser_download_url, context)
        // 关闭背景模糊
        this.foregroundBlurMode = false
      },
      cancel: () => {
        // 关闭背景模糊
        this.foregroundBlurMode = false
      },
      tiltle: `发现新版本${this.latestVersionInfo.tag_name}`,
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

  async aboutToAppear(): Promise<void> {
    LogUtil.info('断点为：' + this.compStr.value)
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
    // 启用监听断点事件
    // BreakpointSystem.getInstance().start()
    BreakpointSystem.getInstance().attach(this.compStr)
    BreakpointSystem.getInstance().attach(this.compVertical)
    BreakpointSystem.getInstance().attach(this.mainEndOffset)
    BreakpointSystem.getInstance().attach(this.mainLeaderboardHeight)
    BreakpointSystem.getInstance().attach(this.mainPageColumnsTemplate)
  }

  aboutToDisappear(): void {
    // 停止监听断点事件，并清空断点对应数据
    BreakpointSystem.getInstance().stop()
  }

}