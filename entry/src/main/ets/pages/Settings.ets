import { LogUtil } from '@pura/harmony-utils'
import { Api, ImageApi, ImageQuality } from '../common/Config'
import { AppConstants } from '../common/Consts'
import { PreferenceManager } from '../utils/preference/Settings'
import { SettingsTitleBar } from './component/TitleBar'
import { HistoryUtil } from '../utils/History'
import SettingsList from './component/SettingsList'
import { ToastUtil } from '../utils/ToastUtils'
import { ColorModeManager } from '../utils/ColorModeManager'
import { SettingsItemAttribute } from '../common/Model'
import { PicState, _PicState } from '../entryability/AppState'
import { homeVM } from '../viewmodel/HomeViewModel'
import { accountVM } from '../viewmodel/AccountViewModel'
import { AccountConfirmDialog } from './component/AccountConfirmDialog'


@Entry
@ComponentV2
struct Settings {

  // 设置页面栈
  private SettingsPageInfos: NavPathStack = new NavPathStack()

  // 退出登录弹窗显隐
  @Local showLogoutDialog: boolean = false

  build() {
    Stack() {
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
                  tips: AppConstants.ApiItems.find(api => api.value == PreferenceManager.api)?.name,
                  menus: AppConstants.ApiItems,
                  menuValue: PreferenceManager.api,
                  onValueChange: (value) => { // 此处value为传递过来的key值
                    LogUtil.info(`value：${value} 切换接口线路: ${Api[value]}`)
                    PreferenceManager.api = Api[value]
                    LogUtil.info(`切换接口线路为: ${PreferenceManager.api}`)
                  }
                },
                {
                  name: '图源线路',
                  type: 'Menu',
                  tips: AppConstants.ImageApiItems.find(imageApi => imageApi.value == PreferenceManager.image_api)?.name,
                  menus: AppConstants.ImageApiItems,
                  menuValue: PreferenceManager.image_api,
                  onValueChange: (value) => {
                    LogUtil.info(`value：${value} 切换图源线路: ${ImageApi[value]}`)
                    PreferenceManager.image_api = ImageApi[value]
                    LogUtil.info(`切换图源线路为: ${PreferenceManager.image_api}`)
                  }
                },
                {
                  name: '图像质量',
                  type: 'Menu',
                  tips: AppConstants.ImageQualityItems.find(imageApi => imageApi.value == PreferenceManager.image_quality)?.name,
                  menus: AppConstants.ImageQualityItems,
                  menuValue: PreferenceManager.image_quality,
                  onValueChange: (value) => {
                    LogUtil.info(`value：${value} 切换图像质量: ${ImageQuality[value]}`)
                    PreferenceManager.image_quality = ImageQuality[value]
                    LogUtil.info(`切换图像质量为: ${PreferenceManager.image_quality}`)
                  },
                }
              ],
              [
                {
                name: '隐私模式',
                type: 'Switch',
                switchByRow: true,
                switchVal: PreferenceManager.privacy_mode,
                onChange: (isOn) => {
                  ToastUtil.animateTo({ duration: 500 }, () => {
                    PreferenceManager.privacy_mode = isOn
                  })
                }
                },
                {
                  name: '颜色模式',
                  type: 'Menu',
                  tips: AppConstants.ColorModeItems.find(mode => mode.key == PreferenceManager.color_mode)?.name,
                  menus: AppConstants.ColorModeItems,
                  menuValue: PreferenceManager.color_mode,
                  onValueChange: (value) => {
                    PreferenceManager.color_mode = value as string
                    ColorModeManager.switchColorMode(_PicState.Context, value as string)
                  }
                }
              ],
              [{
                name: '关于',
                type: 'Normal',
                onClick: () => {
                  this.SettingsPageInfos.pushPathByName('about', false)
                }
              }],
              [{
                name: '清除历史',
                type: 'Normal',
                onClick: () => {
                  HistoryUtil.clear()
                  homeVM.markReadingDirty()
                  homeVM.markHistoryDirty()
                  ToastUtil.showToast({ message: '历史记录清空成功', })
                }
              }],
              ((PicState.token !== undefined && PicState.token.length > 0) ?
                [
                  {
                    name: '账号管理',
                    type: 'Normal',
                    onClick: () => {
                      this.SettingsPageInfos.pushPathByName('account_manage', false)
                    }
                  } as SettingsItemAttribute,
                  {
                    name: '退出登陆',
                    type: 'Normal',
                    onClick: () => {
                      this.showLogoutDialog = true
                    }
                  } as SettingsItemAttribute
                ] : []),
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

      // 退出登录确认弹窗（可勾选"忘记账号密码"）
      AccountConfirmDialog({
        visible: this.showLogoutDialog,
        title: '退出登录',
        message: '确定要退出登录吗？',
        checkText: '同时忘记账号密码',
        onCancel: () => {
          this.showLogoutDialog = false
        },
        onConfirm: (forget: boolean) => {
          this.showLogoutDialog = false
          accountVM.logoutCurrent(forget)
        }
      })
    }
    .width('100%')
    .height('100%')
  }

}

@Builder
export function SettingsPage() {
  Settings()
}