import { bundleManager } from '@kit.AbilityKit'
import { AppConstants } from '../../common/Consts'
import { Api, AppChannel, ImageApi, ImageQuality } from '../../common/Config'
import { HttpUtil } from '../Http'
import { PreferenceUtil } from './PreferenceUtil'


@ObservedV2
export class _PreferenceManager {
  // 配置属性
  @Trace api: Api = Api.Origin
  @Trace image_api: ImageApi = ImageApi.TriageOne
  @Trace image_quality: ImageQuality = ImageQuality.Original
  @Trace channel: AppChannel = AppChannel.One
  @Trace privacy_mode: boolean = false
  @Trace color_mode: string = 'auto'
  @Trace auto_update: boolean = false
  // 阅读设置
  @Trace reader_tap_paging: boolean = true    // 阅读时点击屏幕区域翻页
  @Trace reader_keep_screen_on: boolean = true // 阅读时保持屏幕常亮
  @Trace reader_brightness: number = -1       // 阅读亮度，-1 表示跟随系统

  constructor() {}

  /**
   * 从本地存储加载配置
   */
  public async load(): Promise<void> {
    try {
      const jsonStr: string = await PreferenceUtil.get<string>(AppConstants.KEY_PREFERENCE_SETTINGS, "");
      if (!jsonStr) {
        // 如果没有存储数据，执行默认初始化逻辑
        HttpUtil.init();
        return;
      }

      const json: Record<string, Object> = JSON.parse(jsonStr);
      // 读取配置，如果读取失败则保留默认值
      this.api = (json["api"] as Api) ?? this.api;
      this.image_api = (json["image_api"] as ImageApi) ?? this.image_api;
      this.image_quality = (json["imageQuality"] as ImageQuality) ?? this.image_quality;
      this.channel = (json["channel"] as AppChannel) ?? this.channel;
      this.privacy_mode = (json["privacy_mode"] as boolean) ?? this.privacy_mode;
      this.color_mode = (json["color_mode"] as string) ?? this.color_mode;
      this.auto_update = (json["auto_update"] as boolean) ?? this.auto_update;
      this.reader_tap_paging = (json["reader_tap_paging"] as boolean) ?? this.reader_tap_paging;
      this.reader_keep_screen_on = (json["reader_keep_screen_on"] as boolean) ?? this.reader_keep_screen_on;
      this.reader_brightness = (json["reader_brightness"] as number) ?? this.reader_brightness;
      console.info("[PreferenceManager] 配置加载成功");
      // 根据加载的配置初始化网络请求库
      HttpUtil.init();
    } catch (e) {
      console.error("[PreferenceManager] JSON 解析失败，使用默认配置", e);
      HttpUtil.init();
    }
  }

  /**
   * 监听所有配置项变化，自动保存
   */
  @Monitor('api', 'image_api', 'image_quality', 'channel', 'privacy_mode', 'color_mode', 'auto_update', 'reader_tap_paging', 'reader_keep_screen_on', 'reader_brightness')
  public async save(): Promise<void> {
    try {
      const data: Record<string, Object> = {
        "api": this.api,
        "image_api": this.image_api,
        "image_quality": this.image_quality,
        "channel": this.channel,
        "privacy_mode": this.privacy_mode,
        "color_mode": this.color_mode,
        "auto_update": this.auto_update,
        "reader_tap_paging": this.reader_tap_paging,
        "reader_keep_screen_on": this.reader_keep_screen_on,
        "reader_brightness": this.reader_brightness
      };
      const jsonStr: string = JSON.stringify(data);
      await PreferenceUtil.put(AppConstants.KEY_PREFERENCE_SETTINGS, jsonStr);

      // 当API配置变化时需要重新初始化HttpUtil
      // Monitor 监听到变化时会触发此方法，如果只需要在 api 变化时初始化，可以判断变化类型
      // 每次保存都确保初始化，或者在外部通过 setter 处理特定逻辑
      HttpUtil.init();

    } catch (error) {
      console.error("[PreferenceManager] 保存失败:", error);
    }
  }

  /**
   * 重置为默认配置
   */
  public async reset(): Promise<void> {
    try {
      this.api = Api.Proxy;
      this.image_api = ImageApi.ProxyOne;
      this.image_quality = ImageQuality.Original;
      this.channel = AppChannel.One;
      this.privacy_mode = false;
      this.color_mode = 'auto';
      this.auto_update = false;
      this.reader_tap_paging = true;
      this.reader_keep_screen_on = true;
      this.reader_brightness = -1;

      await this.save(); // 重置后自动保存
      console.info("[PreferenceManager] 配置已恢复默认");
    } catch (error) {
      console.error("[PreferenceManager] 重置失败:", error);
    }
  }

}

// 导出全局单例
export const PreferenceManager = new _PreferenceManager()

// 获取包信息方法
export function getPackageInfo(){
  return bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
}
