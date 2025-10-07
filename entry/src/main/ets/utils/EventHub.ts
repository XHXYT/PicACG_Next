/**
 * copy from XiaoBai Studio
 */

import { emitter } from "@kit.BasicServicesKit";


/**
 * "泛型"事件中心类
 * @param key 必须为number类型
 */
export class EventHub<T> {
  static sendEvent<T>(key: T, data: any = null) {
    emitter.emit({eventId: key as number}, {data: data})
  }

  static on<T>(key: T, callback: (data: any) => void, once: boolean = true) {
    if (once) {
      emitter.off(key as number)
    }
    emitter.on({eventId: key as number},(data)=>{
      callback(data.data)
    })
  }

  static off<T>(key: T) {
    emitter.off(key as number)
  }
}


