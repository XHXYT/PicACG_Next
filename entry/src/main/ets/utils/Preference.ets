import { Api, AppChannel, ImageApi, ImageQuality } from '../common/Config'
import { HttpUtil } from './Http'
import { bundleManager } from '@kit.AbilityKit'

export interface PreferenceItem {
  name: string
  value: string,
  key: string,
  icon?: ResourceStr
}

export class PreferenceStorageKey {
  static readonly APP_CHANNEL: string = 'channel'
  static readonly API: string = 'api'
  static readonly IMAGE_API: string = 'image'
  static readonly IMAGE_QUALITY: string = 'quality'
  static readonly PRIVACY_MODE: string = 'privacy'
  static readonly AUTO_UPDATE: string = 'update'
  static readonly Color_MODE: string = 'color_mode'
}

export class PreferenceManager {
  static readonly ApiItems: PreferenceItem[] = [
    { name: '官方线路', value: Api.Origin, key: 'Origin' },
    { name: '代理线路', value: Api.Proxy, key: 'Proxy' },
  ]
  static readonly ImageQualityItems: PreferenceItem[] = [
    { name: '原画质', value: ImageQuality.Original, key: 'Original' },
    { name: '高画质', value: ImageQuality.High, key: 'High' },
    { name: '中画质', value: ImageQuality.Medium, key: 'Medium' },
    { name: '低画质', value: ImageQuality.Low, key: 'Low' },
  ]
  static readonly ChannelItems: PreferenceItem[] = [
    { name: '线路一', value: AppChannel.One, key: 'One' },
    { name: '线路二', value: AppChannel.Two, key: 'Two' },
    { name: '线路三', value: AppChannel.Three, key: 'Three' },
  ]
  static readonly ImageApiItems: PreferenceItem[] = [
    { name: '代理一', value: ImageApi.ProxyOne, key: 'ProxyOne' },
    { name: '代理二', value: ImageApi.ProxyTwo, key: 'ProxyTwo' },
    { name: '分流一', value: ImageApi.TriageOne, key: 'TriageOne' },
    { name: '分流二', value: ImageApi.TriageTwo, key: 'TriageTwo' },
    { name: '分流三', value: ImageApi.TriageThree, key: 'TriageThree' },
  ]

  static readonly ColorModeItems: PreferenceItem[] = [
    { name: '自动', value: 'auto', key: 'auto' },
    { name: '白天', value: 'light', key: 'light' },
    { name: '夜晚', value: 'dark', key: 'dark' },
  ]

  static init() {
    // Api地址
    PersistentStorage.persistProp<Api>(PreferenceStorageKey.API, Api.Proxy)
    PersistentStorage.persistProp<ImageApi>(PreferenceStorageKey.IMAGE_API, ImageApi.ProxyOne)
    HttpUtil.init()
    // 画质
    PersistentStorage.persistProp<ImageQuality>(PreferenceStorageKey.IMAGE_QUALITY, ImageQuality.Original)
    // 分流
    PersistentStorage.persistProp<AppChannel>(PreferenceStorageKey.APP_CHANNEL, AppChannel.One)
    // 隐私模式
    PersistentStorage.persistProp<boolean>(PreferenceStorageKey.PRIVACY_MODE, false)
    // 颜色模式
    PersistentStorage.persistProp<string>(PreferenceStorageKey.Color_MODE, 'auto')
    // 自动检查更新
    PersistentStorage.persistProp<boolean>(PreferenceStorageKey.AUTO_UPDATE, false)
  }

  static setApi(api: Api) {
    AppStorage.setOrCreate<Api>(PreferenceStorageKey.API, api)
    HttpUtil.init()
  }

  static setImageApi(api: ImageApi) {
    AppStorage.setOrCreate<ImageApi>(PreferenceStorageKey.IMAGE_API, api)
  }

  static setQuality(quality: ImageQuality) {
    AppStorage.setOrCreate<ImageQuality>(PreferenceStorageKey.IMAGE_QUALITY, quality)
  }

  static setChannel(channel: AppChannel) {
    AppStorage.setOrCreate<AppChannel>(PreferenceStorageKey.APP_CHANNEL, channel)
  }

  static setPrivacyMode(mode: boolean) {
    AppStorage.setOrCreate<boolean>(PreferenceStorageKey.PRIVACY_MODE, mode)
  }

  static setAutoUpdate(status: boolean) {
    AppStorage.setOrCreate<boolean>(PreferenceStorageKey.AUTO_UPDATE, status)
  }
}

export function getPackageInfo(){
  return bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
}