import { PreferenceManager } from '../utils/preference/Settings'
import { PicState } from '../entryability/AppState'
import LoginForm from './component/LoginForm'

/**
 * 独立登录页（薄壳）：仅负责背景与全局前景模糊，
 * 表单逻辑在可复用的 LoginForm 组件中
 */
@ComponentV2
export struct Login {

  build() {
    Column() {
      LoginForm()
    }.height('100%').width('100%')
    .backgroundColor($r('app.color.start_window_background'))
    // 全局前景模糊只挂在独立登录页上：账号管理内的添加账号页复用表单时不带这层，
    // 否则设置 sheet 打开（foregroundBlurMode=true）时会把 sheet 内的表单自身模糊
    .foregroundBlurStyle(PicState.foregroundBlurMode ? BlurStyle.Thin : BlurStyle.NONE)
  }
}
