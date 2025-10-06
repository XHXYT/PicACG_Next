import { common, ConfigurationConstant } from "@kit.AbilityKit";

/**
 * 颜色模式工具类
 */
export class ColorModeManager {
  /**
   * 设置颜色模式
   * @param context UIAbilityContext
   * @param mode 模式类型
   */
  static SetColorMode(
    context: common.UIAbilityContext,
    mode: ConfigurationConstant.ColorMode
  ) {
    try {
      context.getApplicationContext().setColorMode(mode);
    } catch (error) {
      console.error(`颜色模式设置失败：${error.mode} message: ${error.message}`)
    }
  }

  /**
   * 切换颜色模式
   * @param context UIAbilityContext
   * @param mode 模式标识（ThemeColorMode）
   */
  static switchColorMode(
    context: common.UIAbilityContext,
    mode: string
  ) {
    const modeMap: Record<string, ConfigurationConstant.ColorMode> = {
      "auto": ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
      "light": ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT,
      "dark": ConfigurationConstant.ColorMode.COLOR_MODE_DARK
    }
    const targetMode = modeMap[mode] as ConfigurationConstant.ColorMode

    ColorModeManager.SetColorMode(context, targetMode)
  }

}


