// 断点
import { BreakpointState } from "../utils/BreakPoint";

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
  lg: false,
  xl: true
})

/**
 * 首页底部偏移量
 */
export const MainEndOffset: BreakpointState<number> = BreakpointState.of({
  sm: 200,
  md: 260,
  lg: 30,
  xl: 60
})

/**
 * 首页底部偏移量
 */
export const MainGridColHeight: BreakpointState<number> = BreakpointState.of({
  sm: 400,
  md: 600,
  lg: 600,
  xl: 600
})