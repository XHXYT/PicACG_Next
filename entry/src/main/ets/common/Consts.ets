import { PreferenceManager, PreferenceStorageKey } from '../utils/Preference'

type RequestMethod = 'GET' | 'POST'

class StorageKey {
  static readonly TOKEN: string = 'authorization'
  static readonly HISTORY: string = 'history'
  static readonly CATEGORY: string = 'category'
  static readonly KEYWORDS: string = 'keywords'
  static readonly SEARCH_HISTORY = 'search_history'
  static readonly FILTER_CATEGORY = 'filter_category'
}

const Ok = 200
const BadRequest = 400
const Unauthorized = 401
const Timeout = 'timeout'

const ReplaceImageApi = (url: string): string => {
  url = url.replaceAll('//static', '/static')
  const api = AppStorage.get<string>(PreferenceStorageKey.IMAGE_API)
  if (api) {
    PreferenceManager.ImageApiItems.forEach(item => {
      url = url.replaceAll(item.value as string, api)
    })
  }
  return url
}

export {
  RequestMethod, StorageKey, Ok, BadRequest, Unauthorized, Timeout, ReplaceImageApi
}