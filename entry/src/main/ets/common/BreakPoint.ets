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