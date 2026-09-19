import { accountVM, AccountInfo } from '../../viewmodel/AccountViewModel'
import { SettingsTitleBar } from '../component/TitleBar'
import { AccountConfirmDialog } from '../component/AccountConfirmDialog'
import { ToastUtil } from '../../utils/ToastUtils'
import { homeVM } from '../../viewmodel/HomeViewModel'
import { UserAvatar } from '../component/UserAvatar'
import { PicState } from '../../entryability/AppState'

@Builder
export function AccountManageBuilder() {
  AccountManage()
}

/**
 * 账号管理路由页
 */
@ComponentV2
export struct AccountManage {

  @Param isMainPage: boolean = false
  @Local stack: NavPathStack = new NavPathStack()

  build() {
    if (this.isMainPage) {
      Navigation(this.stack) {
        AccountManageContent({
          showBack: false,
          navPathStack: this.stack,
        })
      }
      .width('100%')
      .hideTitleBar(true)
      .backgroundColor($r('app.color.start_window_background'))
    } else {
      NavDestination() {
        AccountManageContent({
          showBack: true,
          navPathStack: this.stack,
        })
      }
      .width('100%')
      .hideTitleBar(true)
      .backgroundColor($r('app.color.start_window_background'))
      .onReady((ctx: NavDestinationContext) => {
        this.stack = ctx.pathStack
      })
    }

  }
}

/**
 * 账号管理内容（路由页 / "我的"页半模态共用）
 * 半模态模式下它位于 sheet 内建 Navigation 的首页，没有路由生命周期，
 * 必须由调用方传入 navPathStack，否则跳转重登页时对未绑定的栈 push 会闪退。
 */
@ComponentV2
export struct AccountManageContent {

  /** 路由页模式显示返回键 */
  @Param showBack: boolean = true
  /** 所在路由栈：路由页传 ctx.pathStack，半模态传 sheet 内建 Navigation 的栈 */
  @Param navPathStack: NavPathStack | null = null

  @Local showDeleteDialog: boolean = false
  @Local pendingDelete: AccountInfo | undefined = undefined

  private pushLogin(username: string): void {
    const stack = this.navPathStack ?? PicState.pageStack
    stack.pushPathByName('account_login', username)
  }

  build() {
    Stack() {
      Column() {
        SettingsTitleBar({
          title: '账号管理',
          subtitle: '',
          showBack: this.showBack,
          navPathStack: this.navPathStack,
        })

        List({ space: 12 }) {
          ForEach(accountVM.accounts, (acc: AccountInfo) => {
            ListItem() {
              Row({ space: 12 }) {
                UserAvatar({
                  avatarUrl: acc.avatarUrl,
                  displayName: acc.displayName(),
                  avatarSize: 44
                })

                Column({ space: 2 }) {
                  Text(acc.displayName())
                    .fontWeight(FontWeight.Medium)
                    .fontSize(16)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(acc.username)
                    .fontSize(12)
                    .fontColor($r('app.color.font_color'))
                    .opacity(0.6)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                if (acc.username === accountVM.currentUsername) {
                  Text('当前')
                    .fontSize(12)
                    .fontColor($r('app.color.common_button_background_light'))
                    .border({ width: 1, color: $r('app.color.common_button_background_light') })
                    .borderRadius(50)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                }

                Text('删除')
                  .fontSize(13)
                  .fontColor($r('app.color.font_color'))
                  .border({ width: 1, color: $r('app.color.custom_gray') })
                  .borderRadius(50)
                  .padding({ left: 12, right: 12, top: 5, bottom: 5 })
                  .onClick(() => {
                    this.pendingDelete = acc
                    this.showDeleteDialog = true
                  })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor($r('app.color.listitem_background'))
              .onClick(async () => {
                const ok = await accountVM.switchTo(acc)
                if (ok) {
                  // 切换成功：立即刷新"我的"页用户信息（昵称/头像）
                  homeVM.loadProfile()
                } else {
                  // 无密码/密码失效：跳重登页并预填用户名，可返回
                  this.pushLogin(acc.username)
                }
              })
            }
          }, (acc: AccountInfo) => acc.username)

          // 添加账号：压入登录页（可返回），登录成功后自动回到本页
          ListItem() {
            Row({ space: 6 }) {
              Text('+')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.common_button_background_light'))
              Text('添加账号')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.common_button_background_light'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 14, bottom: 14 })
            .borderRadius(20)
            .backgroundColor($r('app.color.listitem_background'))
            .onClick(() => {
              this.pushLogin('')
            })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .contentEndOffset(75)
      }
      .width('100%')
      .height('100%')

      // 删除账号确认弹窗（可勾选"忘记账号密码"）
      AccountConfirmDialog({
        visible: this.showDeleteDialog,
        title: '删除账号',
        message: `确定删除账号 ${this.pendingDelete?.displayName() ?? ''} 吗？`,
        checkText: '同时忘记该账号密码',
        onCancel: () => {
          this.showDeleteDialog = false
        },
        onConfirm: (forget: boolean) => {
          this.showDeleteDialog = false
          this.doDelete(forget)
        }
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 删除账号：勾选忘记则整条记录删除，否则仅清除密码保留账号名；
   * 删除的是当前账号时同时退出登录
   */
  private async doDelete(forget: boolean): Promise<void> {
    const acc = this.pendingDelete
    if (acc === undefined) {
      return
    }
    const isCurrent = acc.username === accountVM.currentUsername
    await accountVM.removeAccount(acc.username, forget)
    if (isCurrent) {
      await accountVM.clearActiveAccount()
    }
    ToastUtil.showToast({ message: '账号已删除' })
    this.pendingDelete = undefined
  }

}
