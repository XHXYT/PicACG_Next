import { extractUpdateInfo, getUpdateInfo, UpdateInfo } from '../../utils/CheckUpdate'
import SettingsItem from '../component/SettingsItem'
import { SettingsTitleBar } from '../component/TitleBar'
import { promptAction } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { PreferenceStorageKey } from '../../utils/Preference'
import { GoToWeb } from '../../utils/GoWeb'
import { common } from '@kit.AbilityKit'

const context = getContext(this) as common.UIAbilityContext

/**
 * 关于
 */
@Component
export struct About {

  @StorageLink('VersionName') versionName: string = ''
  @Consume('NavSettingsPathStack') SettingsPageInfos: NavPathStack
  // 自动更新变量
  @StorageLink(PreferenceStorageKey.AUTO_UPDATE) autoUpdate: boolean = false
  // 隐私模式变量
  @StorageLink(PreferenceStorageKey.PRIVACY_MODE) privacyMode: boolean = false

  private context = this.getUIContext()

  build() {
    NavDestination() {
      SettingsTitleBar({
        title: '关于',
        showBack: true,
      })

      List({space: 12}) {
        // Logo
        ListItem() {
          Column({space: 15}) {
            Image($rawfile('login_bg.png'))
              .height(320)
              .objectFit(ImageFit.Contain)
              .margin({left: 12, right: 12})
              .foregroundBlurStyle(this.privacyMode ? BlurStyle.Thin : BlurStyle.NONE)
          }.width('100%')
          .justifyContent(FlexAlign.Center)
        }
        // 列表项
        ListItem() {
          SettingsItem({
            group: [
              [
                {
                  name: '应用版本',
                  tips: `${this.versionName}`,
                  type: 'Tips',
                  onClick: () => {}
                }
              ],
              [
                {
                  name: '关于应用',
                  type: 'Normal',
                  onClick: () => {
                    this.SettingsPageInfos.pushPathByName('AboutApp', false)
                  }
                }
              ],
              [
                {
                  name: '检查更新',
                  type: 'Normal',
                  onClick: () => {
                    this.SettingsPageInfos.pushPathByName('CheckUpdate', false)
                  }
                },
                {
                  name: '自动检查更新',
                  type: 'Switch',
                  switchVal: this.autoUpdate,
                  onChange: (isOn) => {
                    this.context.animateTo({ duration: 500 }, () => {
                      this.autoUpdate = isOn
                    })
                  }
                }
              ],

            ]
          })
        }

      }.width('100%')
      .contentEndOffset(85)

    }.width('100%')
    .hideTitleBar(true)
    .backgroundColor($r('app.color.start_window_background'))
  }
}

/**
 *  关于应用
 */
@Component
export struct AboutApp {
  @Consume('NavSettingsPathStack') SettingsPageInfos: NavPathStack
  @StorageProp('isLandscapePhone')  private isLandscapePhone: boolean = false

  build() {
    NavDestination() {
      SettingsTitleBar({
        title: '关于应用',
        subtitle: '',
        showBack: true
      })
      List() {
        ListItem() {
          SettingsItem({
            group: [
              [
                {
                  image: $rawfile('Luxcis.png'),
                  name: '原作者：Luxcis',
                  subtitle: '',
                  onClick: () => {

                  }
                },
               /* {
                  image: $r('app.media.startIcon'),
                  name: '应用原仓库',
                  subtitle: 'https://github.com/Luxcis/PicACG_Next',
                  onClick: () => {
                    GoToWeb('https://github.com/Luxcis/PicACG_Next', context)
                  }
                }*/
              ],
              [
                {
                  image: $rawfile('ya.png'),
                  name: '此分支作者：小雅',
                  subtitle: '',
                  onClick: () => {

                  }
                },
               /* {
                  image: $r('app.media.startIcon'),
                  name: '此分支仓库',
                  subtitle: 'https://github.com/XHXYT/PicACG_Next',
                  onClick: () => {
                    GoToWeb('https://github.com/XHXYT/PicACG_Next', context)
                  }
                }*/
              ],
            ]
          })
        }

      }
      .width('100%')
      .alignListItem(ListItemAlign.Center)
      .contentEndOffset(75)
    }.width('100%')
    .backgroundColor($r('app.color.start_window_background'))
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.SettingsPageInfos.pop(true)
      return true
    })
  }
}

/**
 * 检查更新
 */
@Component
export struct CheckUpdate {
  @Consume latestVersionInfo: UpdateInfo
  @StorageLink('VersionName') versionName: string = ''
  @Consume('NavSettingsPathStack') SettingsPageInfos: NavPathStack
  // 自动更新变量
  @StorageLink(PreferenceStorageKey.AUTO_UPDATE) autoUpdate: boolean = false

  async aboutToAppear(): Promise<void> {
    if (!this.autoUpdate) {
      await this.checkUpdate()
    }
  }

  async checkUpdate() {
    // 检查版本更新
    try {
      const updateInfo = await getUpdateInfo()
      hilog.info(0xFF00, "UpdatetestTag", "Update Info: %{public}s", JSON.stringify(updateInfo))
      const theLatest = extractUpdateInfo(updateInfo)
      if (theLatest !== null) {
        promptAction.showToast({message: '查询成功', duration: 2000 })
        // 查询完成
        this.latestVersionInfo = theLatest
      } else {
        hilog.info(0xFF00, "UpdatetestTag", "提取更新信息失败")
      }
    } catch (err) {
      // 处理错误情况
      const infoError = `Error:${JSON.stringify(err)}`
      promptAction.showToast({message: '查询失败', duration: 2000 })
      hilog.info(0xFF00, "UpdatetestTag", "Info: %{public}s", infoError)
    }
  }

  build() {
    NavDestination() {
      SettingsTitleBar({
        title: '检查更新',
        subtitle: '',
        showBack: true,
      })

      List({space: 12}) {
        // 列表项
        ListItem() {
          SettingsItem({
            group: [
              [
                {
                  name: '当前版本',
                  tips: `${this.versionName}`,
                  type: 'Tips',
                  onClick: () => {}
                },
                {
                  name: '最新版本',
                  tips: `${this.latestVersionInfo.tag_name}`,
                  type: 'Tips',
                  onClick: () => {}
                }
              ],
              [
                {
                  name: '前往更新',
                  onClick: () => {
                    GoToWeb('https://github.com/XHXYT/PicACG_NEXT/releases/', context)
                  }
                }
              ],
              [
                {
                  name: '下载地址',
                  subtitle: this.latestVersionInfo.browser_download_url,
                  onClick: () => {
                    GoToWeb(this.latestVersionInfo.browser_download_url, context)
                  }
                }
              ],

            ]
          })
        }

      }.width('100%')
      .contentEndOffset(75)

    }.width('100%')
    .hideTitleBar(true)
    .backgroundColor($r('app.color.start_window_background'))
  }
}

interface ListInfo {
  image?: Resource,
  name: string,
  subtitle: string
}