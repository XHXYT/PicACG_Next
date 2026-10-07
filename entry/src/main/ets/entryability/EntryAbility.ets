import { AbilityConstant, common, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { bundleManager } from "@kit.AbilityKit";
import { createLogger } from '../utils/Logger';
import { AvoidanceManager, SmartAvoidance } from '../utils/AvoidManager';
import { PicState, _PicState } from './AppState';
import { ToastUtil } from '../utils/ToastUtils';
import { Animation } from '../utils/AnimationUtil';
import { PreferenceUtil } from '../utils/preference/PreferenceUtil';
import { KVDbUtil } from '../utils/preference/KVdbUtil';
import { PreferenceManager } from '../utils/preference/Settings';
import { ImageKnife } from '@ohos/imageknifepro';
import { HttpUtil } from '../utils/Http';
import { StorageKey } from '../common/Consts';
import { accountVM } from '../viewmodel/AccountViewModel';


const logger = createLogger('EntryAbility')
// 断点比例常量
const BREAKPOINT_RATIO_LANDSCAPE = 0.79;
const BREAKPOINT_RATIO_PORTRAIT = 1.2;

export default class EntryAbility extends UIAbility {
  private isFirstStart: boolean = true
  private avoidManager: AvoidanceManager | undefined = undefined;

  // 避让区域变化监听器 - 同步数据到全局变量 PicState
  private avoidListener: (avoidance: SmartAvoidance) => void = (newAvoidance) => {
    PicState.bottomRectHeight = newAvoidance.bottom
    PicState.topRectHeight = newAvoidance.top
    PicState.leftAvoidWidth = newAvoidance.left
  }
  // 窗口三键按钮区域变化监听
  private onTitleButtonRectChange: (rect: window.TitleButtonRect) => void = (rect: window.TitleButtonRect) => {
    PicState.rightAvoidWidth = rect.width + rect.right
  }

  // --- 生命周期 ---
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      await this.initAppEnvironment();
      await this.initAppStateAndAuth();
      logger.info('Init', 'App environment and state initialized successfully.');
    } catch (error) {
      logger.error(`Init`, `Initialization failed, ${error}`);
    }
  }

  onDestroy(): void {
    logger.info('Lifecycle', 'EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    logger.info('Lifecycle', 'EntryAbility onWindowStageCreate');
    const initialUrl = PicState.token !== '' ? 'pages/Index' : 'pages/Login';
    windowStage.loadContent('pages/Index', async (err) => {
      if (err.code) {
        logger.error(`WindowStage`, `Failed to load the content., ${err}`)
        return;
      }
      try {
        const data = await windowStage.getMainWindow()
        // 存储初始化UI上下文 (静态属性赋值)
        _PicState.UIContext = data.getUIContext()
        // 初始化工具类
        ToastUtil.initContext(_PicState.UIContext, _PicState.UIContext.getHostContext() as common.UIAbilityContext)
        Animation.init(_PicState.UIContext)
        // 初始化窗口与UI管理
        this.intRectWindow(windowStage, _PicState.UIContext)
      } catch (error) {
        logger.error(`WindowStage`, `Failed to get the Main Window, ${error}`)
      }
      logger.info('WindowStage', 'Succeeded in loading the content.');
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
  }

  onWindowStageWillDestroy(windowStage: window.WindowStage): void {
    if (this.avoidManager) {
      this.avoidManager.offChangeListener(this.avoidListener);
      this.avoidManager.destroy();
      this.avoidManager = undefined;
    }
    try {
      _PicState.window?.off('windowTitleButtonRectChange', this.onTitleButtonRectChange)
    } catch (error) {
      logger.error(`WindowMode`, `Cleanup listener failed: ${error.message}`)
    }
    logger.info('Lifecycle', 'EntryAbility onWindowStageWillDestroy');
  }

  onWindowStageDestroy(): void {
    logger.info('Lifecycle', 'EntryAbility onWindowStageDestroy');
  }

  onForeground(): void {
    logger.info('Lifecycle', 'EntryAbility onForeground');
  }

  onBackground(): void {
    logger.info('Lifecycle', 'EntryAbility onBackground');
  }

  // --- 核心初始化逻辑 ---
  private async initAppEnvironment() {
    _PicState.Context = this.context
    await PreferenceUtil.init(this.context, 'picacg_preference');
    await KVDbUtil.initKVManager(this.context, 'picacg')
    await PreferenceManager.load()
    await ImageKnife.getInstance().initFileCache(this.context, 256, 256 * 1024 * 1024);
    // 哔咔图片服务（storage-b）会拦截非客户端 UA（403），统一使用官方 App 的 okhttp UA
    ImageKnife.getInstance().addHeader('user-agent', 'okhttp/3.8.1');
    this.initAppVersion()
  }

  private async initAppStateAndAuth() {
    await this.initAccounts()

  }

  private async initAccounts() {
    const savedToken = await KVDbUtil.getData<string>(StorageKey.TOKEN, '');
    // 恢复已保存的账号列表与当前账号标记
    await accountVM.load();
    // token 存在但当前账号标记丢失或账号列表为空 → token 已不可用，清理掉
    if (savedToken && (accountVM.currentUsername === '' || accountVM.accounts.length === 0)) {
      await KVDbUtil.deleteData(StorageKey.TOKEN)
      PicState.token = ''
      return
    }
    if (savedToken) {
      PicState.token = savedToken;
    }
  }

  private async initAppVersion() {
    const packageInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    PicState.appVersion = packageInfo.versionName
  }

  // --- 窗口与UI管理 ---
  /**
   * 初始化窗口
   * 参照项目一的结构：全屏设置 -> 避让区域 -> 尺寸初始化 -> 监听注册
   */
  async intRectWindow(windowStage: window.WindowStage, UIContext: UIContext) {
    // 设置窗口尺寸自动保存 (2in1设备)
    try {
      await windowStage.setWindowRectAutoSave(true);
      logger.info("WindowAutoSave", 'Succeeded in setting window rect auto-save')
    } catch (exception) {
      logger.error("WindowAutoSave", `Failed. Code: ${exception.code}, Message: ${exception.message}`)
    }

    try {
      const windowClass: window.Window = windowStage.getMainWindowSync();

      // 设置全屏模式
      await windowClass.setWindowLayoutFullScreen(true);
      logger.info('WindowRect', 'Set full-screen mode success.');

      // 初始化避让区域管理器 (保留项目二的AvoidanceManager，并桥接到全局变量)
      this.avoidManager = new AvoidanceManager(windowClass, UIContext);
      await this.avoidManager.init();
      this.avoidManager.onChangeListener(this.avoidListener);

      // 初始化窗口尺寸与断点 (一次性赋值)
      this.initWindowDimensions(windowClass, UIContext);

      // 注册窗口变化监听 (动态更新)
      this.registerWindowListeners(windowClass, UIContext);

    } catch (error) {
      logger.error(`WindowInit`, `Failed to init window., ${error}`)
    }
  }

  /**
   * 初始化窗口尺寸数据
   */
  private initWindowDimensions(windowClass: window.Window, UIContext: UIContext) {
    try {
      const properties = windowClass.getWindowProperties()
      const rect = properties.windowRect

      // 单位转换
      const WindowHeightVp = UIContext.px2vp(rect.height)
      const WindowWidthVp = UIContext.px2vp(rect.width)
      const widthBp: WidthBreakpoint = UIContext.getWindowWidthBreakpoint()

      _PicState.window = windowClass;           // 静态：窗口对象
      _PicState.windowWidth_px = rect.width;    // 静态：px宽度
      _PicState.windowHeight_px = rect.height;  // 静态：px高度

      PicState.windowHeight = WindowHeightVp    // 实例：vp高度 (需要响应式更新)
      PicState.windowWidth = WindowWidthVp      // 实例：vp宽度
      PicState.widthBp = widthBp                // 实例：宽度断点

      logger.info('WindowRect', `Init: ${rect.width}px x ${rect.height}px`)

      // 初始化窗口模式
      this.onWindowModeChange(windowClass)
    } catch (error) {
      logger.error(`WindowDimensions`, `Failed to get properties., ${error}`)
    }
  }

  /**
   * 注册窗口状态监听
   */
  private registerWindowListeners(windowClass: window.Window, UIContext: UIContext) {
    // 监听窗口大小变化
    windowClass.on('windowSizeChange', async (data) => {
      const WindowWidthVp = UIContext.px2vp(data.width)!
      const WindowHeightVp = UIContext.px2vp(data.height)!

      // 更新全局变量
      PicState.windowHeight = WindowHeightVp
      PicState.windowWidth = WindowWidthVp
      _PicState.windowWidth_px = data.width
      _PicState.windowHeight_px = data.height

      // 触发断点计算
      this.onWidthBpChange(UIContext)
      this.onHeightBpChange(WindowHeightVp, WindowWidthVp)
    });

    // 监听自由窗口模式变化 (PC端)
    try {
      windowClass.on('freeWindowModeChange', (isFreeMode) => {
        PicState.windowMode = isFreeMode
        this.onWindowModeChange(windowClass)
        logger.debug(`WindowMode`, `Mode changed: ${isFreeMode}`)
      });
    } catch (e) {
      logger.error(`WindowMode`, `Listener failed: ${e.message}`)
    }

    // 监听窗口三键按钮区域变化
    try {
      windowClass.on('windowTitleButtonRectChange', this.onTitleButtonRectChange)
    } catch (error) {
      logger.error(`WindowMode`, `TitleButtonRect listener failed: ${error.message}`)
    }
  }

  // --- 辅助计算方法 ---
  private onWidthBpChange(UIContext: UIContext) {
    const widthBp: WidthBreakpoint = UIContext.getWindowWidthBreakpoint();
    PicState.widthBp = widthBp
  }

  private onHeightBpChange(WindowHeight: number, WindowWidth: number) {
    let heightBp = 0
    const ratio = WindowHeight / WindowWidth
    if (ratio < BREAKPOINT_RATIO_LANDSCAPE) {
      heightBp = 0
    } else if (ratio >= BREAKPOINT_RATIO_LANDSCAPE && ratio < BREAKPOINT_RATIO_PORTRAIT) {
      heightBp = 1
    } else {
      heightBp = 2
    }
    PicState.heightBp = heightBp
  }

  private async onWindowModeChange(windowClass: window.Window) {
    try {
      windowClass.setWindowDecorVisible(false)
      windowClass.setWindowTitleButtonVisible(true, true, true)
      await windowClass.setTitleAndDockHoverShown(false, false)

      if (this.isFirstStart) {
        PicState.windowMode = windowClass.isInFreeWindowMode()
        this.isFirstStart = false
      }
      // PC 模式下读取三键按钮区域宽度，用于右上角内容避让
      if (PicState.windowMode) {
        this.readTitleButtonRect(windowClass)
      } else {
        PicState.rightAvoidWidth = 0
      }
      logger.info("WindowMode", `Current mode: ${PicState.windowMode}, rightAvoid: ${PicState.rightAvoidWidth}`)
    } catch (e) {
      logger.error("WindowMode", `Change error: ${e.message}`)
    }
  }

  /**
   * 读取三键区域宽度写入全局状态（非窗口模式置 0）
   */
  private readTitleButtonRect(windowClass: window.Window): void {
    try {
      const rect: window.TitleButtonRect = windowClass.getTitleButtonRect()
      PicState.rightAvoidWidth = rect.width + rect.right
      logger.info("WindowMode", `Title button rect: width=${rect.width}, right=${rect.right}, total=${PicState.rightAvoidWidth}`)
    } catch (error) {
      const err = error as BusinessError
      logger.error(`WindowMode`, `Failed to get title button rect: ${err.message}`)
    }
  }

}
