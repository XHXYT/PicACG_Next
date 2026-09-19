import { ToastUtil } from '../../utils/ToastUtils'
import { homeVM } from '../../viewmodel/HomeViewModel'
import { SettingsTitleBar } from '../component/TitleBar'
import LoginForm from '../component/LoginForm'

@Builder
export function AccountLoginBuilder() {
  AccountLogin()
}

/**
 * 账号管理内"添加账号 / 账号失效重登"路由页：
 * 跟随所在栈跳转（设置 sheet 内栈 / "我的"页半模态内栈），登录成功后刷新用户信息并返回
 */
@ComponentV2
export struct AccountLogin {
  @Local prefillUsername: string = ''
  @Local stack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column() {
        SettingsTitleBar({
          title: '添加账号',
          subtitle: '',
          showBack: true,
          navPathStack: this.stack,
        })
        LoginForm({
          showSettingsGear: false,
          showQuickAccounts: false,
          showSplash: false,
          prefillUsername: this.prefillUsername,
          onLoginSuccess: () => {
            ToastUtil.showToast({ message: '登录成功' })
            // 立即拉取新账号的用户信息（昵称/头像）
            homeVM.loadProfile()
            this.stack.pop()
          }
        })
      }.width('100%').height('100%')
    }
    .width('100%')
    .hideTitleBar(true)
    .backgroundColor($r('app.color.start_window_background'))
    .onReady((ctx: NavDestinationContext) => {
      this.stack = ctx.pathStack
      // 路由参数：预填用户名（切换账号密码失效时传入）
      const param = ctx.pathInfo.param as string
      if (typeof param === 'string' && param !== '') {
        this.prefillUsername = param
      }
    })
  }
}
