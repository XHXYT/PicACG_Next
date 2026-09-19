import { PreferenceManager } from '../utils/preference/Settings'
import { Api, AppChannel, ImageApi, ImageQuality } from './Config'
import { PreferenceItem } from './Model'
import { Thumb } from '../api/models'

type RequestMethod = 'GET' | 'POST'

class AppConstants {

  static KEY_PREFERENCE_SETTINGS: string = 'key_pic_settings'

  // UI选项列表
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

}

class StorageKey {
  static readonly TOKEN: string = 'authorization'
  static readonly HISTORY: string = 'history'
  static readonly CATEGORY: string = 'category'
  static readonly KEYWORDS: string = 'keywords'
  static readonly SEARCH_HISTORY = 'search_history'
  static readonly FILTER_CATEGORY = 'filter_category'
  // 多账号：已保存账号列表（JSON）、当前登录账号名、密码加密密钥
  static readonly ACCOUNTS: string = 'accounts'
  static readonly CURRENT_ACCOUNT: string = 'current_account'
  static readonly CRYPTO_KEY: string = 'account_crypto_key'
}

const Ok = 200
const BadRequest = 400
const Unauthorized = 401
const Timeout = 'timeout'

const ReplaceImageApi = (url: string): string => {
  url = url.replaceAll('//static', '/static')
  const api = PreferenceManager.api
  if (api) {
    AppConstants.ImageApiItems.forEach(item => {
      url = url.replaceAll(item.value as string, api)
    })
  }
  return url
}

/**
 * 构建图片完整 URL
 * 漫画封面等 static 结构资源走用户配置的图片线路；
 * 头像等存放在独立文件服务（如 storage-b.picacomic.com），
 * 同样需要 /static/ 前缀：fileServer + '/static/' + path，否则服务器返回 401。
 */
const buildImageUrl = (thumb: Thumb): string => {
  if (!thumb.path) {
    return ''
  }
  if (thumb.fileServer.includes('/static')) {
    return `${PreferenceManager.image_api}${thumb.path}`
  }
  const server = thumb.fileServer.endsWith('/') ? thumb.fileServer : `${thumb.fileServer}/`
  return `${server}static/${thumb.path}`
}

export {
  AppConstants, RequestMethod, StorageKey, Ok, BadRequest, Unauthorized, Timeout, ReplaceImageApi, buildImageUrl
}