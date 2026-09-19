import { extractUpdateInfo, getUpdateInfo, UpdateInfo } from '../../utils/CheckUpdate'
import SettingsList from '../component/SettingsList'
import { SettingsTitleBar } from '../component/TitleBar'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { PreferenceManager } from '../../utils/preference/Settings'
import { GoToWeb } from '../../utils/GoWeb'
import { ToastUtil } from '../../utils/ToastUtils'
import { PicState, _PicState } from '../../entryability/AppState'

@Builder
export function AboutBuilder() {
  About()
}


/**
 * 关于
 */
@Component
export struct About {

  private pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      SettingsTitleBar({
        title: '关于',
        showBack: true,
        navPathStack: this.pageInfos,
      })

      List({space: 12}) {
        // Logo
        ListItem() {
          Column({space: 15}) {
            Image($rawfile('login_bg.png'))
              .height(320)
              .objectFit(ImageFit.Contain)
              .margin({left: 12, right: 12})
              .foregroundBlurStyle(PreferenceManager.privacy_mode ? BlurStyle.Thin : BlurStyle.NONE)
          }.width('100%')
          .justifyContent(FlexAlign.Center)
        }
        // 列表项
        ListItem() {
          SettingsList({
            group: [
              [
                {
                  name: '应用版本',
                  tips: `${PicState.appVersion}`,
                  type: 'Tips',
                  onClick: () => {}
                }
              ],
              [
                {
                  name: '关于应用',
                  type: 'Normal',
                  onClick: () => {
                    this.pageInfos.pushPathByName('about_app', false)
                  }
                }
              ],
              [
                {
                  name: '检查更新',
                  type: 'Normal',
                  onClick: () => {
                    this.pageInfos.pushPathByName('check_update', false)
                  }
                },
                {
                  name: '自动检查更新',
                  type: 'Switch',
                  switchVal: PreferenceManager.auto_update,
                  onChange: (isOn) => {
                    ToastUtil.animateTo({ duration: 500 }, () => {
                      PreferenceManager.auto_update = isOn
                    })
                  }
                }
              ],

            ]
          })
        }

      }.width('100%')
      .contentEndOffset(85)
      .padding({ left: 16, right: 16 })

    }.width('100%')
    .hideTitleBar(true)
    .backgroundColor($r('app.color.start_window_background'))
    .onReady((ctx) => {
      this.pageInfos = ctx.pathStack
    })
  }
}

@Builder
export function AboutAppBuilder() {
  AboutApp()
}

/**
 *  关于应用
 */
@Component
export struct AboutApp {

  private pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      SettingsTitleBar({
        title: '关于应用',
        subtitle: '',
        showBack: true,
        navPathStack: this.pageInfos,
      })
      List() {
        ListItem() {
          SettingsList({
            group: [
              [
                {
                  image: $rawfile('Luxcis.png'),
                  name: '原作者：Luxcis',
                  subtitle: '',
                  onClick: () => {

                  }
                },
                {
                  image: $r('app.media.startIcon'),
                  name: '应用原仓库',
                  subtitle: 'https://github.com/Luxcis/PicACG_Next',
                  onClick: () => {
                    GoToWeb('https://github.com/Luxcis/PicACG_Next', _PicState.Context)
                  }
                }
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
                    GoToWeb('https://github.com/XHXYT/PicACG_Next', _PicState.Context)
                  }
                }*/
              ],
            ]
          })
        }

      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignListItem(ListItemAlign.Center)
      .contentEndOffset(75)
    }.width('100%')
    .backgroundColor($r('app.color.start_window_background'))
    .hideTitleBar(true)
    .onReady((ctx) => {
      this.pageInfos = ctx.pathStack
    })
  }

}

@Builder
export function CheckUpdateBuilder() {
  CheckUpdate()
}

/**
 * 检查更新
 */
@Component
export struct CheckUpdate {

  private pageInfos: NavPathStack = new NavPathStack()

  async aboutToAppear(): Promise<void> {
    // 打开页面即检查更新（页面本身就是手动检查入口，不受"自动检查更新"开关影响）
    await this.checkUpdate()
  }

  async checkUpdate() {
    // 检查版本更新
    try {
      const updateInfo = await getUpdateInfo()
      hilog.info(0xFF00, "UpdatetestTag", "Update Info: %{public}s", JSON.stringify(updateInfo))
      const theLatest = extractUpdateInfo(updateInfo)
      if (theLatest !== null) {
        ToastUtil.showToast({message: '查询成功', duration: 2000 })
        // 查询完成
        PicState.latestVersionInfo = theLatest
      } else {
        hilog.info(0xFF00, "UpdatetestTag", "提取更新信息失败")
      }
    } catch (err) {
      // 处理错误情况
      const infoError = `Error:${JSON.stringify(err)}`
      ToastUtil.showToast({message: '查询失败', duration: 2000 })
      hilog.info(0xFF00, "UpdatetestTag", "Info: %{public}s", infoError)
    }
  }

  build() {
    NavDestination() {
      SettingsTitleBar({
        title: '检查更新',
        subtitle: '',
        showBack: true,
        navPathStack: this.pageInfos
      })

      List({space: 12}) {
        // 列表项
        ListItem() {
          SettingsList({
            group: [
              [
                {
                  name: '当前版本',
                  tips: `${PicState.appVersion}`,
                  type: 'Tips',
                  onClick: () => {}
                },
                {
                  name: '最新版本',
                  tips: `${PicState.latestVersionInfo.tag_name}`,
                  type: 'Tips',
                  onClick: () => {}
                }
              ],
              [
                {
                  name: '前往更新',
                  onClick: () => {
                    GoToWeb('https://github.com/XHXYT/PicACG_NEXT/releases/', _PicState.Context)
                  }
                }
              ],
              [
                {
                  name: '下载地址',
                  subtitle: PicState.latestVersionInfo.browser_download_url,
                  onClick: () => {
                    if (PicState.latestVersionInfo.browser_download_url) {
                      GoToWeb(PicState.latestVersionInfo.browser_download_url, _PicState.Context)
                    } else {
                      ToastUtil.showToast({ message: '请先检查更新', duration: 2000 })
                    }
                  }
                }
              ],

            ]
          })
        }

      }.width('100%')
      .contentEndOffset(75)
      .padding({ left: 16, right: 16 })

    }.width('100%')
    .hideTitleBar(true)
    .backgroundColor($r('app.color.start_window_background'))
    .onReady((ctx) => {
      this.pageInfos = ctx.pathStack
    })
  }
}

interface ListInfo {
  image?: Resource,
  name: string,
  subtitle: string
}