
/**
 * 弹窗
 */
@CustomDialog
@Component
export struct TheCustomDialog {

  @State title: string = ''
  @State content: string = ''
  @State rightText: string = ''
  @StorageLink('foregroundBlur') foregroundBlurMode: boolean = false
  confirm: () => void = () => {}
  cancel: () => void = () => {}
  controller: CustomDialogController

  aboutToAppear(): void {
    // 开启背景模糊
    this.foregroundBlurMode = true
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(20)
        .margin({ top: 15, bottom: 15 })
      Text(this.content)
        .textAlign(TextAlign.Center)
        .fontSize(16)
      Flex({direction: FlexDirection.Row}) {
        Button('取消')
          .margin({ top: 15 })
          .width('100%')
          .backgroundColor($r('app.color.start_window_background'))
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
              this.cancel()
            }
          })
          .fontColor($r('app.color.font_color'))
        Button(this.rightText)
          .margin({ top: 15 })
          .width('100%')
          .backgroundColor($r('app.color.common_button_background_light'))
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
              this.confirm()
            }
          })
          .fontColor(Color.White)
      }
    }
    .backgroundColor($r('app.color.start_window_background'))
    .padding({left: 24, right: 24, bottom: 10})
    .borderRadius(32)
  }
}