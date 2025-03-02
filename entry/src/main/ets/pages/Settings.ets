import { DialogUtil, LogUtil } from '@pura/harmony-utils'
import { Api, ImageApi, ImageQuality } from '../common/Config'
import { StorageKey } from '../common/Consts'
import { PreferenceItem, PreferenceManager, PreferenceStorageKey } from '../utils/Preference'
import { SettingsTitleBar } from './component/TitleBar'
import { promptAction, router } from '@kit.ArkUI'
import { DialogAction } from '@pura/harmony-utils/src/main/ets/entity/constraint'
import { HistoryUtil } from '../utils/History'
import SettingsItem from './component/SettingsItem'
import HalfModal from './component/HalfModal'
import { BreakpointState } from '../utils/BreakPoint'
import { deviceInfo } from '@kit.BasicServicesKit'
import { About, AboutApp, CheckUpdate } from './view/About'

@Entry
@Component
struct Settings {
  @StorageProp('topRectHeight') topRectHeight: number = 0
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink(PreferenceStorageKey.API) api: Api = Api.Origin
  @StorageLink(PreferenceStorageKey.IMAGE_API) imageApi: ImageApi = ImageApi.TriageOne
  @StorageLink(PreferenceStorageKey.IMAGE_QUALITY) imageQuality: ImageQuality = ImageQuality.Original
  @Consume('CompStr') compStr: BreakpointState<string>
  // 设置页面栈
  @Provide('NavSettingsPathStack') SettingsPageInfos: NavPathStack = new NavPathStack()
  // 隐私模式变量
  @StorageLink(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false
  @StorageProp(StorageKey.TOKEN) token: string = ''
  @State showApiChannel: boolean = false
  @State showImageChannel: boolean = false
  @State showSettingType: 'Api' | 'Image' = 'Api'
  @State latency: number[] = []

  openApiChannelChange() {
    LogUtil.info('切换接口线路')
    this.showSettingType = 'Api'
    this.showApiChannel = true
  }

  openImageChannelChange() {
    LogUtil.info('切换图片线路')
    this.showSettingType = 'Image'
    this.showImageChannel = true
  }

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
          SettingsItem({
            group: [
              [
                {
                  name: '接口线路',
                  type: 'Normal',
                  onClick: () => {
                    this.openApiChannelChange()
                  }
                },
                {
                  name: '图源线路',
                  type: 'Normal',
                  onClick: () => {
                    this.openImageChannelChange()
                  }
                }
              ],
              [{
                name: '隐私模式',
                type: 'Switch',
                switchVal: this.privacyMode,
                onChange: (isOn) => {
                  animateTo({ duration: 500 }, () => {
                    this.privacyMode = isOn
                  })
                }
              }],
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
                  promptAction.showToast({ message: '浏览历史清空成功', })
                }
              }],
              [{
                name: '退出登陆',
                type: 'Normal',
                show: this.token !== undefined && this.token.length > 0,
                onClick: () => {
                  this.logout()
                }
              }],
            ]
          })
        }

        ListItem() {
          Text('本应用仅供学习交流！')
        }
      }.width('100%')
      .alignListItem(ListItemAlign.Center)
      .contentEndOffset(75)

      HalfModal({
        show: this.showApiChannel,
        view: () => {
          this.ApiChannel()
        },
        options: {
          title: {
            title: '设置',
            subtitle: '接口线路'
          },
          height: SheetSize.FIT_CONTENT,
          showClose: false,
          dragBar: false,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          onDisappear: () => {
            this.showApiChannel = false
          },
        }
      })

      HalfModal({
        show: this.showImageChannel,
        view: () => {
          this.ImageChannel()
        },
        options: {
          title: {
            title: '设置',
            subtitle: '图源线路'
          },
          height: SheetSize.FIT_CONTENT,
          showClose: false,
          dragBar: false,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          onDisappear: () => {
            this.showImageChannel = false
          },
        }
      })
    }
    .width('100%')
    .height('100%')
    .hideToolBar(true)
    .backgroundColor($r('app.color.start_window_background'))
    .navDestination(this.SettingsPagesMap)
    .mode((this.compStr.value === 'md' && deviceInfo.deviceType === 'phone') ? NavigationMode.Stack : NavigationMode.Auto)
  }

  @Builder
  ApiChannel() {
    this.ChannelSetting(PreferenceManager.ApiItem, this.api, Api, PreferenceManager.setApi)
  }

  @Builder
  ImageChannel() {
    this.ChannelSetting(PreferenceManager.ImageApiItem, this.imageApi, ImageApi, PreferenceManager.setImageApi)
  }

  @Builder
  ChannelSetting(channels: PreferenceItem[], currentVal: string, apiEnum: ESObject, set: (v: ESObject) => void) {
    Column() {
      ForEach(channels, (item: PreferenceItem, index: number) => {
        Row() {
          Radio({ value: item.value, group: 'api' })
            .checked(item.value === currentVal)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                set(apiEnum[item.key])
              }
            })

          Text(item.name)
            .onClick(() => {
              set(apiEnum[item.key])
            })
        }
        .width('100%')
        .height(38)
      }, (item: PreferenceItem, index: number) => {
        this.latency[index] = -1;
        return item.name
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: this.bottomRectHeight })
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