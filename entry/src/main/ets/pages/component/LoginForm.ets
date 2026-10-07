import { DialogUtil, LogUtil } from '@pura/harmony-utils'
import { UserLogin } from '../../api/auth'
import { StorageKey, Timeout } from '../../common/Consts'
import { deviceInfo } from '@kit.BasicServicesKit'
import { SettingsPage } from '../Settings'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ToastUtil } from '../../utils/ToastUtils'
import { LoginImageHeight } from '../../utils/breakpoint/BreakPoint'
import { PreferenceManager } from '../../utils/preference/Settings'
import { PicState } from '../../entryability/AppState'
import { KVDbUtil } from '../../utils/preference/KVdbUtil'
import { accountVM, AccountInfo } from '../../viewmodel/AccountViewModel'
import { UserAvatar } from './UserAvatar'

/**
 * 登录表单
 * - 独立登录页：全功能（启动页门槛、已存账号快捷登录、设置入口）
 * - 账号管理内"添加账号"路由页：关闭门槛/快捷入口/设置入口，登录成功后回调
 */
@ComponentV2
export default struct LoginForm {

  /** 是否显示右上角设置入口（独立登录页用） */
  @Param showSettingsGear: boolean = true
  /** 是否显示已保存账号快捷登录行 */
  @Param showQuickAccounts: boolean = true
  /** 是否显示"前往登录"启动门槛 */
  @Param showSplash: boolean = true
  /** 预填用户名 */
  @Param prefillUsername: string = ''
  /** 登录成功回调（状态切换由 PicState.token 驱动，这里只做页面层动作如返回） */
  @Event onLoginSuccess: () => void = () => {
  }

  @Local imageHeight: number = 0
  @Local isShowSettings: boolean = false
  @Local username: string = ''
  @Local password: string = ''
  @Local inLogin: boolean = false
  @Local isLoading: boolean = true

  aboutToAppear(): void {
    hilog.info(0x0000, 'PicaLogin', '进入登录页%{public}s', )
    if ((PicState.token !== '')) {
      hilog.info(0x0000, 'PicaLogin', '已登录%{public}s', )
    } else {
      hilog.info(0x0000, 'PicaLogin', '未登录%{public}s', )
    }
    if (!this.showSplash) {
      this.isLoading = false
    }
    if (this.prefillUsername !== '') {
      this.username = this.prefillUsername
    }
  }

  @Monitor('prefillUsername')
  onPrefillChange(): void {
    // 路由参数在 onReady 才就绪，晚于子组件初始化，这里补一次预填
    if (this.prefillUsername !== '' && this.username === '') {
      this.username = this.prefillUsername
    }
  }

  build() {
    Column() {
      GridRow() {
        // 图标区
        GridCol({span: {sm: 12, md: deviceInfo.deviceType === 'phone' ? 6 : 12, lg: 6}}) {
          Column() {
            Image($rawfile('login_bg.png'))
              .objectFit(ImageFit.Contain)
              .aspectRatio(1)
              .onAreaChange((oldValue: Area, newValue: Area) => {
                this.imageHeight = Number(newValue.height)
              })
              .margin({left: 12, right: 12})
          }.width('100%')
          .justifyContent(FlexAlign.Center)
          .foregroundBlurStyle(PreferenceManager.privacy_mode ? BlurStyle.Thin : BlurStyle.NONE)
          .height(LoginImageHeight(PicState.widthBp))
        }
        // 登录区
        GridCol({span: {sm: 12, md: deviceInfo.deviceType === 'phone' ? 6 : 12, lg: 6}}) {
          Column({space: 10}) {
            if (!this.isLoading) {
              // 已保存账号快捷入口：点击直接用保存的密码登录
              if (this.showQuickAccounts && accountVM.accounts.length > 0) {
                Scroll() {
                  Row({space: 8}) {
                    ForEach(accountVM.accounts, (acc: AccountInfo) => {
                      Row({space: 6}) {
                        UserAvatar({
                          avatarUrl: acc.avatarUrl,
                          displayName: acc.displayName(),
                          avatarSize: 24
                        })
                        Text(acc.displayName())
                          .fontSize(13)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .constraintSize({ maxWidth: 110 })
                      }
                      .alignItems(VerticalAlign.Center)
                      .padding({left: 8, right: 12, top: 6, bottom: 6})
                      .borderRadius(50)
                      .border({ width: 1, color: $r('app.color.custom_gray') })
                      .clickEffect({ level: ClickEffectLevel.LIGHT })
                      .onClick(() => {
                        this.quickLogin(acc)
                      })
                    }, (acc: AccountInfo) => acc.username)
                  }
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .width('80%')
              }

              TextInput({ placeholder: '用户名', text: this.username })
                .type(InputType.USER_NAME)
                .enterKeyType(EnterKeyType.Next)
                .width('80%')
                .onChange(val => {
                  this.username = val
                })
                .onSubmit(() => {
                  focusControl.requestFocus('pwd')
                })

              TextInput({ placeholder: '密码', text: this.password })
                .id('pwd')
                .type(InputType.Password)
                .enterKeyType(EnterKeyType.Done)
                .width('80%')
                .onFocus(() => {
                  LogUtil.info('密码框拿到焦点了')
                })
                .onChange(val => {
                  this.password = val
                })
                .onSubmit(() => {
                  this.doLogin()
                })

              Button({ type: this.inLogin ? ButtonType.Circle : ButtonType.Capsule }) {
                Row() {
                  if (this.inLogin) {
                    LoadingProgress().width(30).height(30).color(Color.White)
                  } else {
                    Text('登录').fontColor(Color.White).textAlign(TextAlign.Center)
                  }
                }.height(40)
              }
              .width('30%')
              .backgroundColor($r('app.color.common_button_background_light'))
              .enabled(!this.inLogin)
              .clickEffect({ level: ClickEffectLevel.LIGHT })
              .onClick(() => {
                this.doLogin()
              })

              if (this.showSettingsGear) {
                Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.TEXTUAL }) {
                  SymbolGlyph($r('sys.symbol.gearshape_fill'))
                    .fontSize(25)
                    .fontColor([$r('app.color.common_button_background_light')])
                }
                .width(40)
                .clickEffect({ level: ClickEffectLevel.LIGHT })
                .onClick(() => {
                  PicState.foregroundBlurMode = true
                  this.isShowSettings = true
                })
                .bindSheet($$this.isShowSettings, SettingsPage(), {
                  detents: [SheetSize.LARGE],
                  dragBar: false,
                  backgroundColor: $r('app.color.start_window_background'),
                  keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
                  scrollSizeMode: ScrollSizeMode.CONTINUOUS,
                  preferType: SheetType.CENTER,
                  onWillDismiss: () => {
                    // 关闭背景模糊
                    PicState.foregroundBlurMode = false
                    // 关闭设置
                    this.isShowSettings = false
                  },
                  onWillSpringBackWhenDismiss: () => {},  // 预防错误回弹
                  onDisappear: () => {}
                })
              }
            } else {
              Button({ type: ButtonType.Capsule }) {
                Row() {
                  Text('前往登录').fontColor(Color.White).textAlign(TextAlign.Center)
                }.height(40)
              }
              .width('30%')
              .backgroundColor($r('app.color.common_button_background_light'))
              .clickEffect({ level: ClickEffectLevel.LIGHT })
              .onClick(() => {
                ToastUtil.animateTo({
                  duration: 690,
                  curve: Curve.ExtremeDeceleration,
                  iterations: 1,
                  playMode: PlayMode.Normal
                }, () => {
                  this.isLoading = false
                })
              })
            }
          }.width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .height(LoginImageHeight(PicState.widthBp))
        }
      }.onBreakpointChange((breakpoint: string) => {
      })

    }.height('100%').width('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.start_window_background'))
  }

  doLogin() {
    if (this.username && this.password) {
      animateTo({ duration: 300 }, () => {
        this.inLogin = true
      })
      UserLogin({ email: this.username, password: this.password })
        .then(async res => {
          LogUtil.info('登陆成功')
          // 持久化 + 更新内存状态，Index 由 PicState.token 状态驱动自动切换到主界面，无需路由跳转
          await KVDbUtil.putData(StorageKey.TOKEN, res.token)
          PicState.token = res.token
          // 记录账号（密码 AES 加密保存），用于多账号切换
          await accountVM.addAccount(this.username, this.password, res.token)
          this.onLoginSuccess()
        })
        .catch((err: Error) => {
          if (Timeout === err.message) {
            DialogUtil.showConfirmDialog({
              title: '提示',
              message: '连接超时！',
              confirm: '确定',
            })
          } else if ('1004: invalid email or password' === err.message) {
            LogUtil.error('登陆失败: 用户名或密码错误')
            DialogUtil.showConfirmDialog({
              title: '提示',
              message: '用户名或密码错误！',
              confirm: '确定',
            })
          } else {
            LogUtil.error(`登陆异常: ${err.name}`)
            LogUtil.error(`登陆异常: ${err.message}`)
            LogUtil.error(`登陆异常: ${err.stack}`)
            DialogUtil.showConfirmDialog({
              title: '提示',
              message: `账号不存在或接口异常`,
              confirm: '确定',
            })
          }
        })
        .finally(() => {
          ToastUtil.animateTo({ duration: 300 }, () => {
            this.inLogin = false
          })
        })
    } else {
      DialogUtil.showConfirmDialog({
        title: '提示',
        message: '请输入用户名密码！',
        confirm: '确定',
      })
    }
  }

  /**
   * 快捷登录：已保存密码的账号一键登录；未保存密码仅填充用户名
   */
  private async quickLogin(acc: AccountInfo): Promise<void> {
    this.username = acc.username
    if (!acc.hasPassword()) {
      this.password = ''
      ToastUtil.showToast({ message: '请输入该账号的密码' })
      return
    }
    const password = await accountVM.getPassword(acc)
    if (password === '') {
      ToastUtil.showToast({ message: '请输入该账号的密码' })
      return
    }
    this.password = password
    this.doLogin()
  }

}
