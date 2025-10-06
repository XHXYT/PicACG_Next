import { promptAction } from "@kit.ArkUI"

class ToastUtils {

  context: UIContext | undefined

  initContext(context: UIContext) {
    this.context = context
  }

  showToast(options: promptAction.ShowToastOptions, key?: string) {
    try {
      this.context?.getPromptAction().showToast(options)
    } catch (error) {
      console.error(`${key} 发送通知失败 code: ${error.code} message: ${error.message}`)
    }
  }

  animateTo(value: AnimateParam, event: () => void, key?: string) {
    try {
      this.context?.animateTo(value, () => {
        event()
      })
    } catch (error) {
      console.error(`${key} 动画加载失败 code: ${error.code} message: ${error.message}`)
    }
  }

}

export const ToastUtil = new ToastUtils()