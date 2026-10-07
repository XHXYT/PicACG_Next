import axios, {
  AxiosError,
  AxiosInstance,
  AxiosRequestConfig,
  AxiosResponse,
  CreateAxiosDefaults,
  InternalAxiosRequestConfig
} from '@ohos/axios'
import { PicaResponse } from '../common/Model'
import { Ok, RequestMethod, StorageKey, Timeout, Unauthorized } from '../common/Consts'
import { HashMap, util } from '@kit.ArkTS'
import {
  Accept,
  Agent,
  Api,
  ApiKey,
  AppNonce,
  AppUuid,
  AppVersion,
  BuildVersion,
  Host,
  Platform,
  SecretKey
} from '../common/Config'
import CryptoJS from '@ohos/crypto-js'
import { PreferenceManager } from './preference/Settings'
import { KVDbUtil } from './preference/KVdbUtil'
import { createLogger } from './Logger'
import { DialogUtil } from '@pura/harmony-utils'
import { ToastUtil } from './ToastUtils'
import { PicState } from '../entryability/AppState'
import { accountVM } from '../viewmodel/AccountViewModel'

const logger = createLogger('HttpUtil')

/** 静默重登响应：与 /auth/sign-in 返回结构一致 */
interface SignInResponse {
  token: string
}


export class HttpUtil {
  private static instance: AxiosInstance
  private static isShowTimeout: boolean = false
  /** 静默重登单飞锁：并发多个 401 只触发一次重登 */
  private static reloginTask: Promise<string> | undefined = undefined
  /** 重登后重放请求的标记头：带此头的请求再次 401 时不再重试，避免死循环 */
  private static readonly RETRIED_HEADER: string = 'X-Pica-Auth-Retried'
  private static readonly SIGN_IN_URL: string = '/auth/sign-in'

  public static init() {
    HttpUtil.instance = axios.create(HttpUtil.defaultConfig())
    HttpUtil.httpInterceptorsRequest()
    HttpUtil.httpInterceptorsResponse()
  }

  public static request<T>(
    method: RequestMethod,
    url: string,
    config?: AxiosRequestConfig<ESObject>
  ): Promise<T> {
    if (config) {
      config.method = method
      config.url = url
    } else {
      config = { method, url }
    }
    return new Promise((resolve, reject) => {
      HttpUtil.instance
        .request(config)
        .then((response: ESObject) => {
          resolve(response)
        })
        .catch((error: AxiosError) => {
          reject(error)
        })
    })
  }

  public static get<T>(url: string, params?: ESObject): Promise<T> {
    return HttpUtil.request<T>('GET', url, { params })
  }

  public static post<T>(url: string, data?: ESObject): Promise<T> {
    return HttpUtil.request<T>('POST', url, { data })
  }

  private static defaultConfig(): CreateAxiosDefaults {
    return {
      baseURL: PreferenceManager.api,
      // 超时时间30秒
      timeout: 15 * 1000,
    }
  }

  private static buildHeader(path: string = '', method: string = 'GET'): HashMap<String, String> {
    const timestamp = (new Date().getTime() / 1000).toFixed(0)
    const nonce = util.generateRandomUUID(true).replaceAll('-', '')

    const header = new HashMap<String, String>()
    header.set('Content-Type', 'application/json; charset=UTF-8')
    header.set('App-channel', PreferenceManager.channel)
    header.set('App-uuid', AppUuid)
    header.set('Accept', Accept)
    header.set('App-Platform', Platform)
    header.set('Time', timestamp)
    header.set('Nonce', nonce)
    header.set('Image-quality', PreferenceManager.image_quality)
    header.set('Signature', HttpUtil.createSignature(path, timestamp, nonce, method))
    if (PreferenceManager.api === Api.Origin) {
      header.set('User-Agent', Agent)
      header.set('Api-key', ApiKey)
      header.set('App-version', AppVersion)
      header.set('App-build-version', BuildVersion)
      header.set('App-nonce', AppNonce)
      header.set('Host', Host)
    }
    return header
  }

  private static createSignature(path: string, timestamp: string, nonce: string, method: string): string {
    if (path.startsWith('/')) {
      path = path.substring(1)
    }
    const raw = (path + timestamp + nonce + method + ApiKey).toLowerCase()
    logger.debug(`SignRaw: ${raw}`)
    const signature = CryptoJS.HmacSHA256(raw, SecretKey).toString(CryptoJS.enc.Hex)
    logger.info(`Signature: ${signature}`)
    return signature
  }

  /**请求拦截器*/
  private static httpInterceptorsRequest() {
    HttpUtil.instance.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
      config.headers[StorageKey.TOKEN] = await KVDbUtil.getData(StorageKey.TOKEN, '')
      // 赋值到全局变量
      PicState.token = config.headers[StorageKey.TOKEN]
      let signUrl = config.url
      if (config.params !== undefined) {
        signUrl += '?' + Object.keys(config.params).map(key => key + '=' + config.params[key]).join('&')
        config.url = signUrl
        config.params = undefined
      }
      HttpUtil.buildHeader(signUrl, config.method).forEach((val: string, key: string) => {
        config.headers[key] = val
      })
      logger.debug(`Host: ${PreferenceManager.api}`)
      logger.debug(`接口[${config.url}]发送请求，请求参数：${JSON.stringify(config.params)}，请求体：${JSON.stringify(config.data)}`)
      return config
    }, (error: AxiosError) => {
      // 对请求错误做些什么
      logger.error(error.message)
      return Promise.reject(error)
    })
  }

  /**响应拦截器*/
  private static httpInterceptorsResponse() {
    HttpUtil.instance.interceptors.response.use((response: AxiosResponse<PicaResponse<ESObject>, ESObject>) => {
      // 对响应数据做点什么
      if (response.status === Ok) {
        logger.debug(`接口[${response.config.url}]请求成功，返回结果：${JSON.stringify(response.data)}`)
        return response.data.data
      } else if (response.status === Unauthorized) {
        return Promise.reject(new Error(`${Unauthorized}`))
      } else {
        return Promise.reject(`${response.data.error}: ${response.data.message}`)
      }
    }, (error: AxiosError<PicaResponse<ESObject>, ESObject>) => {
      // 对响应错误做点什么
      if (error.message.toLowerCase().includes(Timeout)) {
        logger.error(`接口请求失败：连接超时`)
        if (!HttpUtil.isShowTimeout) {
          HttpUtil.isShowTimeout = true
          DialogUtil.showConfirmDialog({
            title: '连接超时',
            message: '请检查网络连通情况，或在设置中修改接口线路后重启应用',
            onWillDismiss: () => {
              HttpUtil.isShowTimeout = false
            }
          })
        }
        return Promise.reject(new Error(Timeout))
      } else if (HttpUtil.isAuthExpired(error) && !HttpUtil.isSignInRequest(error) && !HttpUtil.isAuthRetried(error)) {
        // token 已失效：静默重登后重放原请求（每个请求只重试一次）
        return HttpUtil.handleUnauthorized(error)
      } else {
        if (error.response) {
          // 先把原始响应打出来，定位"服务器回了什么"
          logger.error(`接口[${error.response.config?.url}]HTTP=${error.response.status} ` +
            `dataType=${typeof error.response.data} body=${JSON.stringify(error.response.data)}`)

          if (typeof error.response.data === 'string') {
            return Promise.reject(new Error(error.response.data))
          }
          // 可选链 + 显式判空
          if (error.response.data?.code === Unauthorized) {
            logger.error(`接口[${error.response.config?.url}]请求失败：Unauthorized`)
            return Promise.reject(new Error(`${Unauthorized}`))
          }
          logger.error(`接口[${error.response.config?.url}]请求失败：${error.response.data?.message ?? 'unknown'}`)
          return Promise.reject(error)
        } else {
          logger.error(`接口请求异常：${error.message}`)
          return Promise.reject(error)
        }
      }
    })
  }

  /** 登录态是否失效：HTTP 401，或响应体 code 为 401 */
  private static isAuthExpired(error: AxiosError<PicaResponse<ESObject>, ESObject>): boolean {
    if (error.response === undefined) {
      return false
    }
    if (error.response.status === Unauthorized) {
      return true
    }
    return error.response.data?.code === Unauthorized
  }

  /** 登录接口本身返回 401 属于账密错误，不能再触发静默重登 */
  private static isSignInRequest(error: AxiosError<PicaResponse<ESObject>, ESObject>): boolean {
    if (error.response === undefined) {
      return false
    }
    const url = error.response.config?.url
    if (url === undefined) {
      return false
    }
    return url.includes(HttpUtil.SIGN_IN_URL)
  }

  /** 该请求是否为重登后重放的请求（重放后再次 401 不再重试） */
  private static isAuthRetried(error: AxiosError<PicaResponse<ESObject>, ESObject>): boolean {
    if (error.response === undefined) {
      return false
    }
    return error.response.config?.headers[HttpUtil.RETRIED_HEADER] === '1'
  }

  /** 静默重登（单飞）：并发多个 401 共享同一次重登结果 */
  private static silentRelogin(): Promise<string> {
    if (HttpUtil.reloginTask === undefined) {
      HttpUtil.reloginTask = HttpUtil.doRelogin().finally(() => {
        HttpUtil.reloginTask = undefined
      })
    }
    return HttpUtil.reloginTask
  }

  /**
   * 用当前账号保存的密码静默重登，换取新 token
   * 使用独立 axios 请求绕开请求拦截器，避免携带过期 token 干扰登录
   * 失败说明登录态已无法自动恢复：清除本地 token（Index 自动切回登录页）并提示
   */
  private static async doRelogin(): Promise<string> {
    try {
      const account = accountVM.findCurrent()
      if (account === undefined || !account.hasPassword()) {
        throw new Error('当前账号未保存密码')
      }
      const password = await accountVM.getPassword(account)
      if (password === '') {
        throw new Error('密码解密失败')
      }
      // 用现有实例 + 临时清除 token 的方式，避免拦截器携带过期 token
      const oldToken: string = await KVDbUtil.getData(StorageKey.TOKEN, '') as string
      if (oldToken !== '') {
        await KVDbUtil.deleteData(StorageKey.TOKEN)
      }
      try {
        const res: SignInResponse = await HttpUtil.post<SignInResponse>(HttpUtil.SIGN_IN_URL,
          { email: account.username, password: password }) as SignInResponse
        await KVDbUtil.putData(StorageKey.TOKEN, res.token)
        await accountVM.updateCurrentToken(res.token)
        PicState.token = res.token
        logger.info('静默重登成功，登录态已刷新')
        return res.token
      } finally {
        const now: string = await KVDbUtil.getData(StorageKey.TOKEN, '') as string
        if (now === '' && oldToken !== '') {
          await KVDbUtil.putData(StorageKey.TOKEN, oldToken)
        }
      }
    } catch (e) {
      const err = e as Error
      logger.error(`静默重登失败: ${err.message}`)
      await accountVM.clearActiveAccount()
      ToastUtil.showToast({ message: '登录已过期，请重新登录' })
      throw new Error(`${Unauthorized}`)
    }
  }

  /** 401 统一处理：静默重登成功后重放原请求，失败则按登录失效抛出 */
  private static async handleUnauthorized(error: AxiosError<PicaResponse<ESObject>, ESObject>): Promise<ESObject> {
    if (error.response === undefined) {
      return Promise.reject(new Error(`${Unauthorized}`))
    }
    const url = error.response.config?.url
    try {
      await HttpUtil.silentRelogin()
    } catch (e) {
      const err = e as Error
      logger.error(`接口[${url}]静默重登未成功: ${err.message}`)
      return Promise.reject(new Error(`${Unauthorized}`))
    }
    if (error.response.config === undefined) {
      return Promise.reject(new Error(`${Unauthorized}`))
    }
    // 重放请求仍走请求拦截器：自动带上新 token 并重新签名
    error.response.config.headers[HttpUtil.RETRIED_HEADER] = '1'
    logger.info(`静默重登成功，重试接口[${url}]`)
    return HttpUtil.instance.request<ESObject>(error.response.config)
  }
}