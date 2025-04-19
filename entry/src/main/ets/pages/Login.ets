import { DialogUtil, LogUtil } from '@pura/harmony-utils'
import { UserLogin } from '../api/auth'
import { StorageKey, Timeout } from '../common/Consts'
import router from '@ohos.router'
import { PreferenceStorageKey } from '../utils/Preference'
import { deviceInfo } from '@kit.BasicServicesKit'
import { SettingsPage } from './Settings'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { BreakpointState, BreakpointSystem } from '../utils/BreakPoint'
import { LoginImageHeight } from '../common/BreakPoint'


@Entry
@Component
struct Login {
  // 登录页GridCol高度
  @Provide('LoginImageHeight') loginImageHeight: BreakpointState<string> = LoginImageHeight
  @StorageProp(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @StorageLink('foregroundBlur') foregroundBlurMode: boolean = false
  @StorageLink(StorageKey.TOKEN) token: string = ''
  @State private currentBreakpoint: string = 'md'
  @State private imageHeight: number = 0
  @State isShowSettings: boolean = false
  @State username: string = ''
  @State password: string = ''
  @State inLogin: boolean = false
  @State isLoading: boolean = true

  aboutToAppear(): void {
    BreakpointSystem.getInstance().start()
    BreakpointSystem.getInstance().attach(this.loginImageHeight)
    hilog.info(0x0000, 'PicaLogin', '进入启动页%{public}s', )
    if ((this.token !== '')) {
      hilog.info(0x0000, 'PicaLogin', '已登录%{public}s', )
      router.replaceUrl({ url: 'pages/Index' })
    } else {
      hilog.info(0x0000, 'PicaLogin', '未登录%{public}s', )
      // router.replaceUrl({ url: 'pages/Login' })
    }
  }

  aboutToDisappear(): void {

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
          .foregroundBlurStyle(this.privacyMode ? BlurStyle.Thin : BlurStyle.NONE)
          .height((this.currentBreakpoint === 'md' && deviceInfo.deviceType === 'phone') ? '100%' : this.loginImageHeight.value)
        }
        // 登录区
        GridCol({span: {sm: 12, md: deviceInfo.deviceType === 'phone' ? 6 : 12, lg: 6}}) {
          Column({space: 10}) {
            if (!this.isLoading) {
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
                .type(InputType.NEW_PASSWORD)
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

              Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.TEXTUAL }) {
                SymbolGlyph($r('sys.symbol.gearshape_fill'))
                  .fontSize(25)
                  .fontColor([$r('app.color.common_button_background_light')])
              }
              .width(40)
              .clickEffect({ level: ClickEffectLevel.LIGHT })
              .onClick(() => {
                this.foregroundBlurMode = true
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
                  // 开启背景模糊
                  this.foregroundBlurMode = false
                  // 打开设置
                  this.isShowSettings = false
                }
              })
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
                animateTo({
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
          .height((this.currentBreakpoint === 'md' && deviceInfo.deviceType === 'phone') ? '100%' : this.loginImageHeight.value)
        }
      }.onBreakpointChange((breakpoint: string) => {
        this.currentBreakpoint = breakpoint;
      })

    }.height('100%').width('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.start_window_background'))
    .foregroundBlurStyle(this.foregroundBlurMode ? BlurStyle.Thin : BlurStyle.NONE)
  }

  doLogin() {
    if (this.username && this.password) {
      animateTo({ duration: 300 }, () => {
        this.inLogin = true
      })
      UserLogin({ email: this.username, password: this.password })
        .then(res => {
          LogUtil.info('登陆成功')
          this.token = res.token
          router.replaceUrl({ url: 'pages/Index' })
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
          animateTo({ duration: 300 }, () => {
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

}