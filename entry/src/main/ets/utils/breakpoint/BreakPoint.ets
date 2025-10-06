import { BreakpointFunction } from "./BreakPointStystem"
import { BreakpointFunction2D } from "./BreakPointSystem2D"
import { deviceInfo } from "@kit.BasicServicesKit"

/**Tab栏方向*/
export const TabBarVertical = BreakpointFunction2D<boolean>({
  ['sm']: {['hsm']: false, ['hmd']: false, ['hlg']: false},
  ['md']: {['hsm']: true, ['hmd']: false, ['hlg']: false},
  ['lg']: {['hsm']: true, ['hmd']: true, ['hlg']: true},
  ['xl']: {['hsm']: true, ['hmd']: true, ['hlg']: true},
})

/**Tab栏横向方式-普通*/
export const TabBarAlignItems = BreakpointFunction2D<number>({
  ['sm']: {['hsm']: ItemAlign.Center, ['hmd']: ItemAlign.Center, ['hlg']: ItemAlign.Center},
  ['md']: {['hsm']: ItemAlign.End, ['hmd']: ItemAlign.Center, ['hlg']: ItemAlign.Center},
  ['lg']: {['hsm']: ItemAlign.Center, ['hmd']: ItemAlign.Center, ['hlg']: ItemAlign.Center},
  ['xl']: {['hsm']: ItemAlign.Center, ['hmd']: ItemAlign.Center, ['hlg']: ItemAlign.Center},
})

/**Tab栏位置*/
export const TabBarPosition = BreakpointFunction2D<number>({
  ['sm']: {['hsm']: BarPosition.End, ['hmd']: BarPosition.End, ['hlg']: BarPosition.End},
  ['md']: {['hsm']: BarPosition.Start, ['hmd']: BarPosition.End, ['hlg']: BarPosition.End},
  ['lg']: {['hsm']: BarPosition.Start, ['hmd']: BarPosition.Start, ['hlg']: BarPosition.Start},
  ['xl']: {['hsm']: BarPosition.Start, ['hmd']: BarPosition.Start, ['hlg']: BarPosition.Start},
})

/** @description Tab栏竖向方式*/
export const TabBarJustifyContent = BreakpointFunction2D<number>({
  ['sm']: {['hsm']: FlexAlign.Start, ['hmd']: FlexAlign.Start, ['hlg']: FlexAlign.Start},
  ['md']: {['hsm']: FlexAlign.Center, ['hmd']: FlexAlign.Start, ['hlg']: FlexAlign.Start},
  ['lg']: {['hsm']: FlexAlign.Center, ['hmd']: FlexAlign.Center, ['hlg']: FlexAlign.Center},
  ['xl']: {['hsm']: FlexAlign.Center, ['hmd']: FlexAlign.Center, ['hlg']: FlexAlign.Center},
})

/**Tab栏宽度*/
export const TabBarWidth = BreakpointFunction2D<string>({
  ['sm']: {['hsm']: '100%', ['hmd']: '100%', ['hlg']: '100%'},
  ['md']: {['hsm']: '77vp', ['hmd']: '100%', ['hlg']: '100%'},
  ['lg']: {['hsm']: '67vp', ['hmd']: '67vp', ['hlg']: '67vp'},
  ['xl']: {['hsm']: '67vp', ['hmd']: '67vp', ['hlg']: '67vp'},
})

/**Tab栏宽度-窗口*/
export const WindowTabBarWidth = BreakpointFunction2D<string>({
  ['sm']: {['hsm']: '100%', ['hmd']: '100%', ['hlg']: '100%'},
  ['md']: {['hsm']: '57vp', ['hmd']: '100%', ['hlg']: '100%'},
  ['lg']: {['hsm']: '57vp', ['hmd']: '57vp', ['hlg']: '57vp'},
  ['xl']: {['hsm']: '57vp', ['hmd']: '57vp', ['hlg']: '57vp'},
})

/**Tab栏高度-避让底部*/
export const TabBarAvoidHeight = BreakpointFunction2D<string>({
  ['sm']: {['hsm']: '67vp', ['hmd']: '77vp', ['hlg']: '77vp'},
  ['md']: {['hsm']: '100%', ['hmd']: '77vp', ['hlg']: '77vp'},
  ['lg']: {['hsm']: '100%', ['hmd']: '100%', ['hlg']: '100%'},
  ['xl']: {['hsm']: '100%', ['hmd']: '100%', ['hlg']: '100%'},
})

/**Tab栏高度-不避让底部*/
export const TabBarHeight = BreakpointFunction2D<string>({
  ['sm']: {['hsm']: '57vp', ['hmd']: '57vp', ['hlg']: '57vp'},
  ['md']: {['hsm']: '100%', ['hmd']: '57vp', ['hlg']: '57vp'},
  ['lg']: {['hsm']: '100%', ['hmd']: '100%', ['hlg']: '100%'},
  ['xl']: {['hsm']: '100%', ['hmd']: '100%', ['hlg']: '100%'},
})

/**Tab栏字体大小*/
export const TabTitleFontSize = BreakpointFunction2D<number>({
  ['sm']: {['hsm']: 12, ['hmd']: 12, ['hlg']: 12},
  ['md']: {['hsm']: 12, ['hmd']: 16, ['hlg']: 16},
  ['lg']: {['hsm']: 16, ['hmd']: 16, ['hlg']: 16},
  ['xl']: {['hsm']: 16, ['hmd']: 16, ['hlg']: 16},
})

/**Tab栏图标大小*/
export const TabIconFontSize = BreakpointFunction2D<number>({
  ['sm']: {['hsm']: 24, ['hmd']: 24, ['hlg']: 24},
  ['md']: {['hsm']: 24, ['hmd']: 26, ['hlg']: 26},
  ['lg']: {['hsm']: 26, ['hmd']: 26, ['hlg']: 26},
  ['xl']: {['hsm']: 26, ['hmd']: 26, ['hlg']: 26},
})

/**弹窗宽度*/
export const CustomDialogWidth = BreakpointFunction<number>({
  ['sm']: 332, ['md']: 360, ['lg']: 400, ['xl']: 400
})

/**视频列表Grid列数*/
export const VideoListColumnsTemplate = BreakpointFunction<string>({
  ['sm']: "1fr 1fr 1fr",
  ['md']: "1fr 1fr 1fr 1fr",
  ['lg']: "1fr 1fr 1fr 1fr 1fr",
  ['xl']: "1fr 1fr 1fr 1fr 1fr 1fr"
})

/**视频目录列表Grid列数*/
export const VideoCategoryColumnsTemplate = BreakpointFunction<string>({
  ['sm']: "1fr",
  ['md']: "1fr 1fr",
  ['lg']: "1fr 1fr 1fr 1fr",
  ['xl']: "1fr 1fr 1fr 1fr 1fr"
})

/**首页轮播图显示数量*/
export const HomeBannerDisplayCount = BreakpointFunction<number>({
  ['sm']: 1, ['md']: 2, ['lg']: 3, ['xl']: 3
})

/**首页轮播图前&后边距（前后露出的部分）*/
export const HomeBannerBannerMargin = BreakpointFunction<number>({
  ['sm']: 0, ['md']: 12, ['lg']: 64, ['xl']: 64
})

/**登录页图片区高度*/
export const LoginImageHeight = BreakpointFunction<string>({
  ['sm']: '50%', ['md']: '50%', ['lg']: '100%', ['xl']: '100%'
})





