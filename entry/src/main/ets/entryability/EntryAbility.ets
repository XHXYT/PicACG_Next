import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { display, router, window } from '@kit.ArkUI'
import { BusinessError } from '@ohos.base'
import { AppUtil, LogUtil } from '@pura/harmony-utils'
import { StorageKey } from '../common/Consts'
import { PreferenceManager, PreferenceStorageKey } from '../utils/Preference'
import { ImageKnife } from '@ohos/imageknife'
import { HistoryUtil } from '../utils/History'
import { ToastUtil } from '../utils/ToastUtils'
import { ColorModeManager } from '../utils/ColorModeManager'

export default class EntryAbility extends UIAbility {

  private uiContext?: UIContext;
  // 设备断点获取
  private onWindowSizeChange: (windowSize: window.Size) => void = (windowSize: window.Size) => {
    let widthBp: WidthBreakpoint = this.uiContext!.getWindowWidthBreakpoint();
    AppStorage.setOrCreate('currentWidthBreakpoint', widthBp);
    console.log(`断点测试 widthBp: ${widthBp}`)
  };

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'PicaAbilityLog', '%{public}s', 'Ability onCreate')
    AppUtil.init(this.context)
    LogUtil.init(0x0000, 'PicaLog', true)
    await HistoryUtil.init()
    await ImageKnife.getInstance().initFileCache(this.context, 256, 256 * 1024 * 1024)
  }

  onDestroy(): void {
    hilog.info(0x0000, 'PicaAbilityLog', '%{public}s', 'Ability onDestroy')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'PicaAbilityLog', '%{public}s', 'Ability onWindowStageCreate')

    let loadPage: string = 'pages/Login'
    hilog.info(0x0000, 'PicaAbilityTokenLog', 'token: %{public}s', AppStorage.get<string>(StorageKey.TOKEN))

    windowStage.loadContent('pages/Login', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'PicaAbilityLog', 'Failed to load the content. Cause: %{public}s',
          JSON.stringify(err) ?? '')
        return
      }
      hilog.info(0x0000, 'PicaAbilityLog', 'Succeeded in loading the content.')
      // 初始化变量
      PersistentStorage.persistProp(StorageKey.TOKEN, '')
      PersistentStorage.persistProp(StorageKey.HISTORY, [])
      PersistentStorage.persistProp(StorageKey.SEARCH_HISTORY, [])
      PersistentStorage.persistProp(StorageKey.FILTER_CATEGORY, [])
      PreferenceManager.init()
      ColorModeManager.switchColorMode(this.context, AppStorage.get<string>(PreferenceStorageKey.Color_MODE)!)
    })


    windowStage.getMainWindow((err, windowClass) => {
      if (err.code) {
        hilog.error(0x0000, 'PicaAbilityLog', 'Failed to load the content. Cause: %{public}s',
          JSON.stringify(err) ?? '')
        return
      }

      // 全屏
      windowClass.setWindowLayoutFullScreen(true)
        .then(() => {
          LogUtil.info('已成功将窗口布局设置为全屏模式')
        })
        .catch((err: BusinessError) => {
          LogUtil.error('无法将窗口布局设置为全屏模式 Cause:' + JSON.stringify(err))
        })
    })

    windowStage.getMainWindow(async (err, data) => {
      // 全屏
      data.setWindowLayoutFullScreen(true)
        .then(() => {
          console.info('已成功将窗口布局设置为全屏模式')
        })
        .catch((err: BusinessError) => {
          console.error('无法将窗口布局设置为全屏模式 Cause:' + JSON.stringify(err))
        })

      try {
        const UIContext = data.getUIContext()
        this.uiContext = UIContext
        AppStorage.setOrCreate('UIContext', UIContext)
        // 初始化通知
        ToastUtil.initContext(UIContext)
        // 设备宽度断点获取
        const widthBp: WidthBreakpoint = UIContext.getWindowWidthBreakpoint()
        AppStorage.setOrCreate('currentWidthBreakpoint', widthBp)
        data.on('windowSizeChange', this.onWindowSizeChange)
        // 初始化窗口
        this.intRectWindow(windowStage)
      } catch (error) {
        console.error(`UI上下文获取失败，code: ${error.code} message: ${error.messsage}`)
      }

    })

  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'PicaAbilityLog', '%{public}s', 'Ability onWindowStageDestroy')
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'PicaAbilityLog', '%{public}s', 'Ability onForeground')
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'PicaAbilityLog', '%{public}s', 'Ability onBackground')
  }

  private intRectWindow(windowStage: window.WindowStage) {
    // 获取应用主窗口
    try {
      const windowClass: window.Window = windowStage.getMainWindowSync()
      // 设置窗口全屏
      windowClass.setWindowLayoutFullScreen(true).then(() => {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        console.error('Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
      });

      // 缓存window窗口对象
      AppStorage.setOrCreate('WindowClass', windowClass)
      console.info('Succeeded in 保存窗口对象.');

      // 获取布局避让遮挡的区域
      // 获取导航栏遮挡区域
      const bottomType = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR
      try {
        const avoidArea = windowClass.getWindowAvoidArea(bottomType)
        const bottomRectHeight = avoidArea.bottomRect.height
        AppStorage.setOrCreate('bottomRectHeight', px2vp(bottomRectHeight))
        hilog.info(0x0000, 'EntryAbility', '导航栏初始避让高度 Top：%{public}d Bottom: %{public}i', bottomRectHeight);
      } catch (error) {
        console.error(`导航栏避让获取失败，code: ${error.code} message: ${error.messsage}`)
      }

      // 获取状态栏避让遮挡的区域
      const topType = window.AvoidAreaType.TYPE_SYSTEM // 状态栏
      try {
        const topAvoidArea = windowClass.getWindowAvoidArea(topType)
        const topRectHeight = topAvoidArea.topRect.height
        AppStorage.setOrCreate('topRectHeight', this.uiContext?.px2vp(topRectHeight))
        hilog.info(0x0000, 'EntryAbility', '状态栏初始避让高度 Top：%{public}d Bottom: %{public}i', topRectHeight)
      } catch (error) {
        console.error(`状态栏避让获取失败，code: ${error.code} message: ${error.messsage}`)
      }

      // 注册监听函数，动态获取避让区域数据
      windowClass.on('avoidAreaChange', (data) => {
        let topRectActiveHeight = 0
        let bottomRectActiveHeight = 0
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          topRectActiveHeight = data.area.topRect.height;
          AppStorage.setOrCreate('topRectHeight', this.uiContext?.px2vp(topRectActiveHeight));
        } else if (data.type == window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          bottomRectActiveHeight = this.uiContext?.px2vp(data.area.bottomRect.height)!;
          AppStorage.setOrCreate('bottomRectHeight', bottomRectActiveHeight);
        }
        hilog.info(0x0000, 'EntryAbility', '动态避让高度 Top：%{public}d Bottom: %{public}i', topRectActiveHeight, bottomRectActiveHeight);
      });

      // 应用窗口初始高度和宽度
      try {
        const properties = windowClass.getWindowProperties()
        const rect = properties.windowRect
        let WindowHeight = this.uiContext?.px2vp(rect.height)
        let WindowWidth = this.uiContext?.px2vp(rect.width)
        hilog.info(0x0000, 'Pica WindowLog', '窗口高度：%{public}d px 宽度：%{public}i px', rect.height, rect.width)
        AppStorage.setOrCreate('WindowHeight', WindowHeight)
        AppStorage.setOrCreate('WindowWidth', WindowWidth)
        // 监听窗口大小变化
        try {
          windowClass.on('windowSizeChange', async (data) => {
            console.info('#WindowChange Succeeded in enabling the listener for window size changes. Data: ' +
            JSON.stringify(data))
            WindowWidth = this.uiContext?.px2vp(data.width)!
            WindowHeight = this.uiContext?.px2vp(data.height)!
            AppStorage.setOrCreate('windowWidth', WindowWidth)
            AppStorage.setOrCreate('windowHeight', WindowHeight) // 980px 约等于 512vp
            // 动态监听高度断点
            this.onHeightBpChange(WindowHeight, WindowWidth)
          })
        } catch (exception) {
          console.error(`#EntryAbility Failed to enable the listener for window size changes. Cause code: ${exception.code}, message: ${exception.message}`)
        }
      } catch (error) {
        console.error(`窗口大小获取失败，code: ${error.code} message: ${error.messsage}`)
      }
    } catch (error) {
      console.error(`窗口对象获取失败，code: ${error.code} message: ${error.messsage}`)
    }

  }

  private onHeightBpChange(WindowHeight: number, WindowWidth: number) {
    let heightBp = 0
    const WindowAspectRatio = WindowHeight / WindowWidth // 重写高度断点
    if (WindowAspectRatio < 0.79) {
      heightBp = 0
      AppStorage.setOrCreate('currentHeightBreakpoint', heightBp)
      console.log(`断点测试 heightBp: ${heightBp} 高宽比：${WindowAspectRatio}`)
    } else if (WindowAspectRatio >= 0.79 && WindowAspectRatio < 1.2) {
      heightBp = 1
      AppStorage.setOrCreate('currentHeightBreakpoint', heightBp)
      console.log(`断点测试 heightBp: ${heightBp} 高宽比：${WindowAspectRatio}`)
    } else if (WindowAspectRatio >= 1.2) {
      heightBp = 2
      AppStorage.setOrCreate('currentHeightBreakpoint', heightBp)
      console.log(`断点测试 heightBp: ${heightBp} 高宽比：${WindowAspectRatio}`)
    }
  }

}
