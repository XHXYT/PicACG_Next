// 断点
import { BreakpointState } from "../utils/BreakPoint";
import { deviceInfo } from "@kit.BasicServicesKit"

/**
 * 断点名称
 */
export const CompStr: BreakpointState<string> = BreakpointState.of({
  sm: "sm",
  md: "md",
  lg: "lg",
  xl: "xl"
})

/**
 * 入口页tab栏模式  F F F T
 */
export const TabVertical: BreakpointState<boolean> = BreakpointState.of({
  sm: false,
  md: false,
  lg: true,
  xl: true
})

/**
 * 首页底部偏移量
 */
export const MainEndOffset: BreakpointState<number> = BreakpointState.of({
  sm: 120,
  md: 100,
  lg: 30,
  xl: 60
})

/**
 * 首页Grid列数
 */
export const MainPageColumnsTemplate: BreakpointState<string> = BreakpointState.of({
  sm: '1fr',
  md: '1fr',
  lg: '1fr 1fr',
  xl: '1fr 1fr'
})

/**
 * 首页排行榜高度
 */
export const MainLeaderboardHeight: BreakpointState<number> = BreakpointState.of({
  sm: 200,
  md: deviceInfo.deviceType === 'tablet' ? 520 : 360,
  lg: 600,
  xl: 600
})

/**
 * 登录页图片区高度
 */
export const LoginImageHeight: BreakpointState<string> = BreakpointState.of({
  sm: '50%',
  md: '50%',
  lg: '100%',
  xl: '100%'
})

