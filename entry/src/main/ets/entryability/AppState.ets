import { common, ConfigurationConstant } from "@kit.AbilityKit";
import { window } from "@kit.ArkUI"
import { UpdateInfo } from "../utils/CheckUpdate";

@ObservedV2
export class _PicState {

  @Trace token: string = ''
  @Trace appVersion: string = ''
  @Trace latestVersionInfo: UpdateInfo = {tag_name: this.appVersion, name: '1.1.1', published_at: '2024-03-01T15:13:58Z', browser_download_url: ''}

  @Trace category: string[] = []
  @Trace filterCategory: string[] = []
  @Trace keywords: string[] = []

  public pageStack: NavPathStack = new NavPathStack()

  // 窗口对象
  public static UIContext: UIContext
  public static Context: common.UIAbilityContext
  public static window: window.Window;
  /** @description 窗口高度 -px */
  public static windowWidth_px: number;
  /** @description 窗口高度 -px */
  public static windowHeight_px: number;
  /** @description 状态栏高度 -px */
  public static topAvoidAreaHeight_px: number;
  /** @description 导航栏高度 -px */
  public static navigationIndicatorHeight_px: number;
  /** @description 导航栏高度 */
  @Trace bottomRectHeight: number = 0
  /** @description 状态栏高度 */
  @Trace topRectHeight: number = 0
  /** @description 左侧避让宽度 */
  @Trace leftAvoidWidth: number = 0
  /** @description 右侧避让宽度 */
  @Trace rightAvoidWidth: number = 0
  /** @description 窗口高度 -vp */
  @Trace windowHeight: number = 0
  /** @description 窗口宽度 -vp */
  @Trace windowWidth: number = 0
  /** @description 当前宽度断点 */
  @Trace widthBp: number = 0
  /** @description 当前宽度断点 */
  @Trace heightBp: number = 0
  /** @description 窗口模式 true为PC窗口模式 false为普通窗口模式 */
  @Trace windowMode: boolean = false

  @Trace foregroundBlurMode: boolean = false
  @Trace currentColorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT

}

export const PicState = new _PicState()