import { DialogUtil, LogUtil } from '@pura/harmony-utils'
import { Api, ImageApi, ImageQuality } from '../common/Config'
import { StorageKey } from '../common/Consts'
import { PreferenceManager, PreferenceStorageKey } from '../utils/Preference'
import { SettingsTitleBar } from './component/TitleBar'
import { router } from '@kit.ArkUI'
import { DialogAction } from '@pura/harmony-utils/src/main/ets/entity/constraint'
import { HistoryUtil } from '../utils/History'
import SettingsList, { SettingsItemAttribute } from './component/SettingsList'
import { About, AboutApp, CheckUpdate } from './view/About'
import { ToastUtil } from '../utils/ToastUtils'
import { common } from '@kit.AbilityKit'
import { ColorModeManager } from '../utils/ColorModeManager'

@Entry
@Component
struct Settings {
  @StorageProp('topRectHeight') topRectHeight: number = 0
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink(PreferenceStorageKey.API) api: Api = Api.Proxy
  @StorageLink(PreferenceStorageKey.IMAGE_API) imageApi: ImageApi = ImageApi.TriageOne
  @StorageLink(PreferenceStorageKey.IMAGE_QUALITY) imageQuality: ImageQuality = ImageQuality.Original
  // 设置页面栈
  @Provide('NavSettingsPathStack') SettingsPageInfos: NavPathStack = new NavPathStack()
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext
  // 隐私模式变量
  @StorageLink(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @StorageLink(PreferenceStorageKey.Color_MODE) color_mode: string = 'auto'
  @StorageProp(StorageKey.TOKEN) token: string = ''
  @State showApiChannel: boolean = false
  @State showImageChannel: boolean = false
  @State showSettingType: 'Api' | 'Image' = 'Api'
  @State latency: number[] = []

  logout() {
    DialogUtil.showConfirmDialog({
      title: '提示',
      message: '连接超时！',
      confirm: '确定',
      onAction: (action: number) => {
        if (action === DialogAction.TWO) {
          router.replaceUrl({ url: 'pages/Login' })
            .then(() => {
              AppStorage.setOrCreate<string>(StorageKey.TOKEN, '')
            })
        }
      }
    })
  }

  build() {
    Navigation(this.SettingsPageInfos) {
      SettingsTitleBar({
        title: '设置',
      })

      List({space: 12}) {
        ListItem() {
          SettingsList({
            group: [
              [
                {
                  name: '接口线路',
                  type: 'Menu',
                  tips: PreferenceManager.ApiItems.find(api => api.value == this.api)?.name,
                  menus: PreferenceManager.ApiItems,
                  menuValue: this.api,
                  onValueChange: (value) => { // 此处value为传递过来的key值
                    LogUtil.info(`value：${value} 切换接口线路: ${Api[value]}`)
                    PreferenceManager.setApi(Api[value])
                    LogUtil.info(`切换接口线路为: ${this.api}`)
                  }
                },
                {
                  name: '图源线路',
                  type: 'Menu',
                  tips: PreferenceManager.ImageApiItems.find(imageApi => imageApi.value == this.imageApi)?.name,
                  menus: PreferenceManager.ImageApiItems,
                  menuValue: this.imageApi,
                  onValueChange: (value) => {
                    LogUtil.info(`value：${value} 切换图源线路: ${ImageApi[value]}`)
                    PreferenceManager.setImageApi(ImageApi[value])
                    LogUtil.info(`切换图源线路为: ${this.imageApi}`)
                  }
                },
                {
                  name: '图像质量',
                  type: 'Menu',
                  tips: PreferenceManager.ImageQualityItems.find(imageApi => imageApi.value == this.imageQuality)?.name,
                  menus: PreferenceManager.ImageQualityItems,
                  menuValue: this.imageQuality,
                  onValueChange: (value) => {
                    LogUtil.info(`value：${value} 切换图像质量: ${ImageQuality[value]}`)
                    PreferenceManager.setImageApi(ImageQuality[value])
                    LogUtil.info(`切换图像质量为: ${this.imageQuality}`)
                  },
                }
              ],
              [
                {
                name: '隐私模式',
                type: 'Switch',
                switchVal: this.privacyMode,
                onChange: (isOn) => {
                  ToastUtil.animateTo({ duration: 500 }, () => {
                    this.privacyMode = isOn
                  })
                }
                },
                {
                  name: '颜色模式',
                  type: 'Menu',
                  tips: PreferenceManager.ColorModeItems.find(mode => mode.key == this.color_mode)?.name,
                  menus: PreferenceManager.ColorModeItems,
                  menuValue: this.color_mode,
                  onValueChange: (value) => {
                    this.color_mode = value as string
                    ColorModeManager.switchColorMode(this.context, value as string)
                  }
                }
              ],
              [{
                name: '关于',
                type: 'Normal',
                onClick: () => {
                  this.SettingsPageInfos.pushPathByName('About', false)
                }
              }],
              [{
                name: '清除历史',
                type: 'Normal',
                onClick: () => {
                  HistoryUtil.clear()
                  ToastUtil.showToast({ message: '浏览历史清空成功', })
                }
              }],
              ((this.token !== undefined && this.token.length > 0) ?
                [{
                  name: '退出登陆',
                  type: 'Normal',
                  onClick: () => {
                    this.logout()
                  }
                } as SettingsItemAttribute ] : []),
            ]
          })
        }

        ListItem() {
          Text('本应用不提供任何服务，服务内容源自平台，此应用仅供学习交流！')
        }.width('90%')
      }.width('100%')
      .padding({ left: 16, right: 16 })
      .alignListItem(ListItemAlign.Center)
      .contentEndOffset(75)
    }
    .width('100%')
    .height('100%')
    .hideToolBar(true)
    .backgroundColor($r('app.color.start_window_background'))
    .navDestination(this.SettingsPagesMap)
  }

  /**
   * 设置页路由表
   */
  @Builder
  SettingsPagesMap(name: string) {
    if (name === 'About') {
      About()
    } else if ( name === 'CheckUpdate') {
      CheckUpdate()
    } else if ( name === 'AboutApp') {
      AboutApp()
    }
  }

}

@Builder
export function SettingsPage() {
  Settings()
}