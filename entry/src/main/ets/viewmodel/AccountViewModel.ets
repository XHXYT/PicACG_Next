import { LogUtil } from '@pura/harmony-utils'
import { KVDbUtil } from '../utils/preference/KVdbUtil'
import { StorageKey, buildImageUrl } from '../common/Consts'
import { UserLogin } from '../api/auth'
import { User } from '../api/models'
import { PicState } from '../entryability/AppState'
import { ToastUtil as AppToastUtil } from '../utils/ToastUtils'
import { decryptText, encryptText } from '../utils/CryptoUtil'

/** 账号列表持久化结构 */
interface AccountJSON {
  username: string
  nickname: string
  avatarUrl: string
  encPassword: string
  token: string
}

/** 已保存的账号 */
@ObservedV2
export class AccountInfo {
  @Trace username: string = ''
  @Trace nickname: string = ''
  @Trace avatarUrl: string = ''
  /** AES-GCM 加密后的密码，空串表示未保存密码 */
  @Trace encPassword: string = ''
  /** 该账号最近一次登录的 token */
  @Trace token: string = ''

  hasPassword(): boolean {
    return this.encPassword !== ''
  }

  displayName(): string {
    return this.nickname !== '' ? this.nickname : this.username
  }
}

/**
 * 多账号管理 ViewModel（单例）
 * - 登录成功后 addAccount 记录账号（密码 AES 加密存储）
 * - switchTo 用保存的密码静默重登实现切换；失败由调用方跳重登页预填用户名
 * - 删除账号 / 退出登录支持"忘记账号密码"
 */
@ObservedV2
export class AccountViewModel {
  /** 已保存的账号列表 */
  @Trace accounts: AccountInfo[] = []
  /** 当前登录账号名（未登录为空） */
  @Trace currentUsername: string = ''
  /** 正在切换账号中（防重复点击） */
  @Trace switching: boolean = false

  /** 启动时从 KVDB 恢复账号列表与当前账号 */
  async load(): Promise<void> {
    try {
      const json = await KVDbUtil.getData<string>(StorageKey.ACCOUNTS, '[]')
      const parsed = JSON.parse(json) as AccountJSON[]
      const list: AccountInfo[] = []
      parsed.forEach((item: AccountJSON) => {
        const acc = new AccountInfo()
        acc.username = item.username
        acc.nickname = item.nickname
        acc.avatarUrl = item.avatarUrl
        acc.encPassword = item.encPassword
        acc.token = item.token
        list.push(acc)
      })
      this.accounts = list
      this.currentUsername = await KVDbUtil.getData<string>(StorageKey.CURRENT_ACCOUNT, '')
      LogUtil.info(`AccountViewModel 已加载 ${this.accounts.length} 个账号`)
    } catch (e) {
      LogUtil.error(`加载账号列表失败: ${JSON.stringify(e)}`)
    }
  }

  /** 持久化账号列表 */
  private async persist(): Promise<void> {
    const arr: AccountJSON[] = []
    this.accounts.forEach((a: AccountInfo) => {
      const item: AccountJSON = {
        username: a.username,
        nickname: a.nickname,
        avatarUrl: a.avatarUrl,
        encPassword: a.encPassword,
        token: a.token
      }
      arr.push(item)
    })
    await KVDbUtil.putData(StorageKey.ACCOUNTS, JSON.stringify(arr))
  }

  find(username: string): AccountInfo | undefined {
    const matched = this.accounts.filter(a => a.username === username)
    return matched.length > 0 ? matched[0] : undefined
  }

  /** 登录成功后调用：新增或更新账号记录（密码 AES 加密保存） */
  async addAccount(username: string, password: string, token: string): Promise<void> {
    try {
      const encPwd = password !== '' ? await encryptText(password) : ''
      const existing = this.find(username)
      if (existing !== undefined) {
        existing.token = token
        if (encPwd !== '') {
          existing.encPassword = encPwd
        }
      } else {
        const acc = new AccountInfo()
        acc.username = username
        acc.encPassword = encPwd
        acc.token = token
        this.accounts.push(acc)
      }
      this.currentUsername = username
      await KVDbUtil.putData(StorageKey.CURRENT_ACCOUNT, username)
      await this.persist()
      LogUtil.info(`AccountViewModel 已保存账号 ${username}`)
    } catch (e) {
      LogUtil.error(`保存账号信息失败: ${JSON.stringify(e)}`)
    }
  }

  /** 个人信息加载成功后同步昵称头像 */
  async syncProfile(user: User): Promise<void> {
    try {
      const acc = this.find(user.email)
      if (acc === undefined) {
        return
      }
      acc.nickname = user.name
      if (user.avatar !== undefined) {
        acc.avatarUrl = buildImageUrl(user.avatar)
      }
      await this.persist()
    } catch (e) {
      LogUtil.error(`同步账号昵称头像失败: ${JSON.stringify(e)}`)
    }
  }

  /**
   * 删除账号记录
   * @param forgetPassword true=整条记录删除（忘记账号密码）；false=保留账号名，仅清除密码与 token
   */
  async removeAccount(username: string, forgetPassword: boolean): Promise<void> {
    const acc = this.find(username)
    if (acc === undefined) {
      return
    }
    if (forgetPassword) {
      const remain: AccountInfo[] = []
      this.accounts.forEach(a => {
        if (a.username !== username) {
          remain.push(a)
        }
      })
      this.accounts = remain
    } else {
      acc.encPassword = ''
      acc.token = ''
    }
    await this.persist()
  }

  /** 清除当前登录态（不动账号记录），Index 自动切回登录页 */
  async clearActiveAccount(): Promise<void> {
    try {
      await KVDbUtil.deleteData(StorageKey.TOKEN)
    } catch (e) {
      LogUtil.error(`清除登录凭证失败: ${JSON.stringify(e)}`)
    }
    try {
      await KVDbUtil.deleteData(StorageKey.CURRENT_ACCOUNT)
    } catch (e) {
      LogUtil.error(`清除当前账号标记失败: ${JSON.stringify(e)}`)
    }
    PicState.token = ''
    this.currentUsername = ''
    // 卸载登录态会连带卸载设置 sheet 宿主，onWillDismiss 不会触发，需在此同步关闭背景模糊
    PicState.foregroundBlurMode = false
  }

  /**
   * 退出登录
   * @param forgetPassword true=同时删除该账号记录（忘记账号密码）；false=保留记录便于一键重登
   */
  async logoutCurrent(forgetPassword: boolean): Promise<void> {
    const username = this.currentUsername
    if (forgetPassword && username !== '') {
      await this.removeAccount(username, true)
    }
    await this.clearActiveAccount()
  }

  /** 解密某账号保存的密码，失败返回空串 */
  async getPassword(account: AccountInfo): Promise<string> {
    if (!account.hasPassword()) {
      return ''
    }
    try {
      return await decryptText(account.encPassword)
    } catch (e) {
      LogUtil.error(`解密账号密码失败: ${JSON.stringify(e)}`)
      return ''
    }
  }

  /**
   * 切换到指定账号：用保存的密码静默重登
   * - 无密码或密码失效：不清除当前登录态，由调用方跳重登页预填用户名
   * @returns 是否切换成功
   */
  async switchTo(account: AccountInfo): Promise<boolean> {
    if (this.switching) {
      return false
    }
    if (account.username === this.currentUsername && PicState.token !== '') {
      AppToastUtil.showToast({ message: '已是当前账号' })
      return true
    }
    if (!account.hasPassword()) {
      AppToastUtil.showToast({ message: '该账号未保存密码，请重新登录' })
      return false
    }
    this.switching = true
    AppToastUtil.showToast({ message: `正在切换到 ${account.displayName()}...` })
    try {
      const password = await decryptText(account.encPassword)
      const res = await UserLogin({ email: account.username, password: password })
      account.token = res.token
      await KVDbUtil.putData(StorageKey.TOKEN, res.token)
      await KVDbUtil.putData(StorageKey.CURRENT_ACCOUNT, account.username)
      this.currentUsername = account.username
      await this.persist()
      PicState.token = res.token
      AppToastUtil.showToast({ message: `已切换到 ${account.displayName()}` })
      return true
    } catch (e) {
      LogUtil.error(`切换账号失败: ${JSON.stringify(e)}`)
      // 保存的密码已失效：清除失效密码，保留当前登录态，由调用方跳重登页
      account.encPassword = ''
      account.token = ''
      await this.persist()
      AppToastUtil.showToast({ message: '该账号密码已失效，请重新登录' })
      return false
    } finally {
      this.switching = false
    }
  }
}

export const accountVM = new AccountViewModel()
