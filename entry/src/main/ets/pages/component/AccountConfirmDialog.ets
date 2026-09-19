/**
 * 带勾选框的确认弹窗（用于退出登录/删除账号时勾选"忘记账号密码"）
 * 以 Stack 覆盖层方式内嵌到页面中，通过 visible 控制显隐
 */
@ComponentV2
export struct AccountConfirmDialog {
  @Param visible: boolean = false
  @Param title: string = ''
  @Param message: string = ''
  @Param checkText: string = '同时忘记账号密码'
  @Event onCancel: () => void = () => {
  }
  @Event onConfirm: (forget: boolean) => void = (_forget: boolean) => {
  }
  @Local forget: boolean = false

  @Monitor('visible')
  onVisibleChange(): void {
    if (this.visible) {
      // 每次打开重置勾选状态
      this.forget = false
    }
  }

  build() {
    if (this.visible) {
      Stack() {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(0x66000000)
          .onClick(() => {
            this.onCancel()
          })

        // 弹窗卡片
        Column() {
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.font_color'))
            .margin({ bottom: 12 })

          Text(this.message)
            .fontSize(15)
            .fontColor($r('app.color.font_color'))
            .textAlign(TextAlign.Center)
            .lineHeight(22)

          Row({ space: 8 }) {
            Checkbox()
              .select(this.forget)
              .selectedColor($r('app.color.common_button_background_light'))
              .onChange((value: boolean) => {
                this.forget = value
              })
            Text(this.checkText)
              .fontSize(14)
              .fontColor($r('app.color.font_color'))
              .onClick(() => {
                this.forget = !this.forget
              })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ top: 18 })

          Divider()
            .color($r('app.color.custom_gray'))
            .margin({ top: 20 })

          Row() {
            Text('取消')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .fontSize(16)
              .fontColor($r('app.color.font_color'))
              .padding({ top: 12, bottom: 12 })
              .onClick(() => {
                this.onCancel()
              })
            Divider()
              .vertical(true)
              .height(22)
              .color($r('app.color.custom_gray'))
            Text('确定')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.common_button_background_light'))
              .padding({ top: 12, bottom: 12 })
              .onClick(() => {
                this.onConfirm(this.forget)
              })
          }
          .width('100%')
        }
        .width('76%')
        .borderRadius(20)
        .backgroundColor($r('app.color.start_window_background'))
        .padding({ top: 22, bottom: 6, left: 18, right: 18 })
      }
      .width('100%')
      .height('100%')
    }
  }
}
