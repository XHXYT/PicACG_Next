import { window } from '@kit.ArkUI'
import { ImageInfo, ImageKnifeComponentV2 } from '@ohos/imageknifepro'
import { AppUtil, LogUtil } from '@pura/harmony-utils'
import { chapter, eps } from '../../api/comic'
import { ComicDetailInfo, ComicEp } from '../../api/models'
import { PreferenceManager } from '../../utils/preference/Settings'
import { TitleBar, TitleType } from '../component/TitleBar'
import { HistoryUtil } from '../../utils/History'
import HalfModal from '../component/HalfModal'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ToastUtil } from '../../utils/ToastUtils'
import { AppConstants } from '../../common/Consts'
import { ColorModeManager } from '../../utils/ColorModeManager'
import { PreferenceItem } from '../../common/Model'
import { PicState, _PicState } from '../../entryability/AppState'
import { homeVM } from '../../viewmodel/HomeViewModel'


@Builder
export function ComicReaderBuilder(name: string, param: Object) {
  ComicReader()
}

@ComponentV2
export default struct ComicReader {

  @Local detail?: ComicDetailInfo = undefined
  // 目录
  @Local eps: ComicEp[] = []
  @Local page: number = 1
  @Local maxPage: number = 1
  @Local images: string[] = []
  @Local title: string = ''
  @Local isEnd: boolean = false
  @Local showToolbar: boolean = false
  @Local showEps: boolean = false
  @Local showReadingSettings: boolean = false
  @Local disappear: TransitionEffect = TransitionEffect.move(TransitionEdge.START)
  @Local scaleValue: number = 1
  @Local pinchValue: number = 1;
  @Local offsetX: number = 0;
  @Local offsetY: number = 0;
  @Local positionX: number = 0;
  @Local positionY: number = 0;
  @Local currentImageIndex: number = 0
  @Local readerBrightness: number =
    PreferenceManager.reader_brightness >= 0 ? PreferenceManager.reader_brightness : 0.5
  // 亮度条尺寸信息（onAreaChange 回调获取，用于手势坐标换算）
  @Local brightnessBarWidth: number = 0
  private brightnessBarX: number = 0

  private scroll: Scroller = new Scroller()
  private inPan: boolean = false
  private isSliding: boolean = false
  private lastPanY: number = 0
  private canSaveHistory = false
  // 待恢复的阅读页码（-1 表示无）：目标页未加载完前不执行跳转，用户中途滚动则取消
  private pendingRestore: number = -1

  build() {
    NavDestination() {
      Stack() {
        List({ scroller: this.scroll }) {
          ForEach(this.images, (img: string) => {
            ImageKnifeComponentV2({
              imageKnifeOption: {
                loadSrc: img,
                placeholderSrc: $r('app.media.loading'),
                objectFit: ImageFit.Auto,
                onLoadListener: {
                  onLoadFailed: (err: string, imageInfo: ImageInfo) => {
                    LogUtil.error('图片加载失败：', err, ' - ', img)
                    LogUtil.error(JSON.stringify(imageInfo))
                  }
                }
              },
            })
              .width('100%')
              .transition(TransitionEffect.asymmetric(TransitionEffect.move(TransitionEdge.BOTTOM), this.disappear))
          })
        }
        .width('100%')
        .height('100%')
        .contentStartOffset(PicState.topRectHeight)
        .scrollBar(BarState.Off)
        .scale({ x: this.scaleValue, y: this.scaleValue, z: 1 })
        .offset({ x: this.offsetX, y: this.offsetY })
        .onScrollIndex((start: number, end: number) => {
          LogUtil.info(`currentIndex: ${start} - ${end}`)
          // 恢复跳转执行前 pendingRestore 已清空，此处 start>0 必来自用户滚动——取消恢复避免抢占
          // （start=0 可能是列表初始布局回调，不视为用户滚动）
          if (this.pendingRestore >= 0 && start > 0) {
            this.pendingRestore = -1
            this.canSaveHistory = true
          }
          // 拖动进度条期间以滑块值为准，避免 onScrollIndex 回写导致滑块被拉回
          if (!this.isSliding) {
            this.currentImageIndex = start
          }
          this.isEnd = end + 5 >= this.images.length
          if (this.isEnd && this.page < this.maxPage) {
            LogUtil.info('onReachEnd到底辣！！！要加载更多')
            this.page++
            ToastUtil.animateTo({ duration: 500 }, () => {
              this.load()
            })
          }
          // 保存阅读进度：初始布局与恢复跳转期间的回调不得保存，否则会把旧进度抹成 0
          if (this.canSaveHistory) {
            HistoryUtil.setRead(this.detail?._id!, this.detail?.lastReadOrder!, this.currentImageIndex)
            homeVM.markReadingDirty()
          }
        })
        .onWillScroll((scrollOffset) => {
          if (this.inPan) {
            return { offsetRemain: 0 }
          }
          return { offsetRemain: scrollOffset }
        })
        .gesture(GestureGroup(GestureMode.Exclusive,
          // 双指缩放
          PinchGesture({ fingers: 2 })
            .onActionStart(e => {
            LogUtil.info('双指缩放开始，当前缩放倍率：', this.scaleValue.toString());
          })
            .onActionUpdate(e => {
            if (e) {
              this.scaleValue = this.pinchValue * e.scale;
              LogUtil.info('正在执行缩放，当前缩放倍率：', this.scaleValue.toString());
            }
          })
            .onActionEnd(e => {
              ToastUtil.animateTo({ duration: 300 }, () => {
              if (this.scaleValue < 1) {
                this.scaleValue = 1
                this.offsetX = 0
                this.offsetY = 0
              } else if (this.scaleValue > 3) {
                this.scaleValue = 3
              }
            })
            this.pinchValue = this.scaleValue;
            LogUtil.info('双指缩放结束，当前缩放倍率：', this.scaleValue.toString());
          }),
          // 拖动平移
          PanGesture()
            .onActionStart((event: GestureEvent | undefined) => {
            LogUtil.info(`拖动开始，当前偏移：${this.offsetX} ${this.offsetY}`);
            this.inPan = true
          })
            .onActionUpdate((event: GestureEvent | undefined) => {
            if (event && this.scaleValue > 1) {
              // 动态计算缩放后的组件宽高
              const scaledWidth = PicState.windowWidth * this.scaleValue;
              const scaledHeight = PicState.windowHeight * this.scaleValue;
              // 容器的边界
              const containerLeft = 0;
              const containerRight = PicState.windowWidth;
              const containerTop = 0;
              const containerBottom = PicState.windowHeight;
              // 组件的边界（拖动后不能超过容器的范围）
              const minX = containerLeft - (scaledWidth - PicState.windowWidth) / 2;
              const maxX = containerRight - PicState.windowWidth + (scaledWidth - PicState.windowWidth) / 2;
              const minY = containerTop - (scaledHeight - PicState.windowHeight) / 2;
              const maxY = containerBottom - PicState.windowHeight + (scaledHeight - PicState.windowHeight) / 2;
              // 更新偏移量，并限制在边界内
              const newOffsetX = this.positionX + event.offsetX * 5;
              const newOffsetY = this.positionY + event.offsetY * 3;

              this.offsetX = Math.min(Math.max(newOffsetX, minX), maxX);
              this.offsetY = Math.min(Math.max(newOffsetY, minY), maxY);
              LogUtil.info(`正在拖动，当前偏移：${this.offsetX} ${this.offsetY}`);
            }
          })
            .onActionEnd(() => {
              ToastUtil.animateTo({ duration: 300 }, () => {
              if (this.scaleValue === 1) {
                this.offsetX = 0
                this.offsetY = 0
              }
            })
            this.positionX = this.offsetX;
            this.positionY = this.offsetY;
            LogUtil.info(`拖动结束，当前偏移：${this.offsetX} ${this.offsetY}`);
            this.inPan = false
          }),
          // 单击
          TapGesture({ count: 1, fingers: 1 }).onAction((event) => {
            // 关闭“点击翻页”时，任意位置单击只负责呼出/收起工具栏
            if (!PreferenceManager.reader_tap_paging) {
              LogUtil.info('点击翻页已关闭，切换工具栏')
              ToastUtil.animateTo({ duration: 300 }, () => {
                this.showToolbar = !this.showToolbar
                this.showSystemBar(this.showToolbar)
              })
              return
            }
            LogUtil.info('触发单击')
            let x = event.fingerList[0].globalX
            let y = event.fingerList[0].globalY
            if (x < PicState.windowWidth * 0.34 || y < PicState.windowHeight * 0.3) {
              LogUtil.info('点击上一页')
              ToastUtil.animateTo({ duration: 500 }, () => {
                this.scroll.scrollTo({
                  xOffset: 0,
                  yOffset: this.scroll.currentOffset().yOffset - PicState.windowHeight + 300,
                  animation: true
                })
              })
            } else if (x > PicState.windowWidth * 0.66 || y > PicState.windowHeight * 0.7) {
              LogUtil.info('点击下一页')
              ToastUtil.animateTo({ duration: 500 }, () => {
                this.scroll.scrollTo({
                  xOffset: 0,
                  yOffset: this.scroll.currentOffset().yOffset + PicState.windowHeight - 300,
                  animation: true
                })
              })
            } else {
              LogUtil.info('点击中间')
              ToastUtil.animateTo({ duration: 300 }, () => {
                this.showToolbar = true
                this.showSystemBar(true)
              })
            }
          }),
        ))

        if (this.showToolbar) {
          Column() {
            Column()
              .width('100%')
              .height(PicState.topRectHeight)
              .backgroundColor($r('app.color.start_window_background'))
            TitleBar({
              title: this.title,
              rightType: TitleType.CUSTOM,
              rightCustomView: () => {
                this.rightBuilder()
              }
            })
              .transition(TransitionEffect.move(TransitionEdge.TOP))

            Row() {
              // 空白区
              Column()
                .width('90%')
                .height('100%')
                .gesture(GestureGroup(GestureMode.Exclusive,
                  // 拖动平移
                  PanGesture()
                    .onActionStart((event: GestureEvent | undefined) => {
                      LogUtil.info(`拖动开始，当前偏移：${this.offsetX} ${this.offsetY}`);
                      // 注意：此处不能设置 inPan——onWillScroll 会借它拦截一切即时滚动，
                      // 遮罩层下的 List 收不到手势，本就无需屏蔽原生滚动
                      this.lastPanY = 0
                    })
                    .onActionUpdate((event: GestureEvent | undefined) => {
                      if (event && this.scaleValue > 1) {
                        // 动态计算缩放后的组件宽高
                        const scaledWidth = PicState.windowWidth * this.scaleValue;
                        const scaledHeight = PicState.windowHeight * this.scaleValue;
                        // 容器的边界
                        const containerLeft = 0;
                        const containerRight = PicState.windowWidth;
                        const containerTop = 0;
                        const containerBottom = PicState.windowHeight;
                        // 组件的边界（拖动后不能超过容器的范围）
                        const minX = containerLeft - (scaledWidth - PicState.windowWidth) / 2;
                        const maxX = containerRight - PicState.windowWidth + (scaledWidth - PicState.windowWidth) / 2;
                        const minY = containerTop - (scaledHeight - PicState.windowHeight) / 2;
                        const maxY = containerBottom - PicState.windowHeight + (scaledHeight - PicState.windowHeight) / 2;
                        // 更新偏移量，并限制在边界内
                        const newOffsetX = this.positionX + event.offsetX * 5;
                        const newOffsetY = this.positionY + event.offsetY * 3;

                        this.offsetX = Math.min(Math.max(newOffsetX, minX), maxX);
                        this.offsetY = Math.min(Math.max(newOffsetY, minY), maxY);
                        LogUtil.info(`正在拖动，当前偏移：${this.offsetX} ${this.offsetY}`);
                      } else if (event) {
                        // 未缩放：按手指增量即时滚动，内容跟随手指（上滑=向后翻页）
                        const dy = event.offsetY - this.lastPanY
                        this.lastPanY = event.offsetY
                        this.scroll.scrollTo({
                          xOffset: 0,
                          yOffset: this.scroll.currentOffset().yOffset - dy
                        })
                      }
                    })
                    .onActionEnd((event: GestureEvent | undefined) => {
                      ToastUtil.animateTo({ duration: 300 }, () => {
                        if (this.scaleValue === 1) {
                          this.offsetX = 0
                          this.offsetY = 0
                        }
                      })
                      this.positionX = this.offsetX;
                      this.positionY = this.offsetY;
                      // 未缩放时按离手速度抛滑，模拟原生滚动惯性
                      // fling：正值向顶部滚、负值向底部滚，与 velocityY（vp/s）方向一致
                      if (event && this.scaleValue === 1 && Math.abs(event.velocityY) > 50) {
                        try {
                          this.scroll.fling(event.velocityY)
                        } catch (e) {
                          LogUtil.error(`fling 惯性滚动失败: ${JSON.stringify(e)}`)
                        }
                      }
                      LogUtil.info(`拖动结束，当前偏移：${this.offsetX} ${this.offsetY}`);
                    }),
                  // 单击
                  TapGesture({ count: 1, fingers: 1 }).onAction((event) => {
                    LogUtil.info('触发空白区域单击')
                    ToastUtil.animateTo({ duration: 300 }, () => {
                      this.showToolbar = false
                      this.showSystemBar(false)
                    })
                  })
                ))
              // 滑动条
              Column() {
                Slider({
                  value: $$this.currentImageIndex,
                  max: this.images.length - 1,
                  style: SliderStyle.OutSet,
                  direction: Axis.Vertical
                })
                  .blockColor($r('app.color.custom_pink'))
                  .trackColor($r('app.color.common_button_background_light'))
                  .selectedColor($r('app.color.common_button_background_weight'))
                  .showTips(true, `${this.currentImageIndex}`)
                  .onChange((value: number, mode: SliderChangeMode) => {
                    if (mode === SliderChangeMode.Begin) {
                      this.isSliding = true
                    }
                    this.currentImageIndex = value
                    // 拖动过程中即时定位，带动画会造成列表追赶滑块的顿挫感
                    this.scroll.scrollToIndex(value, false)
                    if (mode === SliderChangeMode.End) {
                      this.isSliding = false
                    }
                  })
              }
              .width('10%')
              .height('100%')
            }
            .width('100%')
            .height('100%')
            .layoutWeight(1)
            // 导航栏
            Row() {
              Button() {
                Row() {
                  SymbolGlyph($r('sys.symbol.chevron_left'))
                    .fontSize(25)
                    .fontColor([$r('app.color.common_button_background_light')])
                  Text('上一章')
                    .fontColor($r('app.color.common_button_background_light'))
                    .margin({ left: 10 })
                }
              }
              .width('34%')
              .height('100%')
              .stateEffect(false)
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .type(ButtonType.Normal)
              .enabled(this.detail?.lastReadOrder! > 1)
              .onClick(() => {
                this.goToEp(this.detail?.lastReadOrder! - 1)
                LogUtil.info(`点击上一章, this.detail?.lastReadOrder!: ${this.detail?.lastReadOrder!}`)
              })

              Button() {
                Row() {
                  Text('目录')
                    .fontColor($r('app.color.common_button_background_light'))
                }
              }
              .width('32%')
              .height('100%')
              .stateEffect(false)
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .type(ButtonType.Normal)
              // .enabled(!this.showEps)
              .onClick(() => {
                ToastUtil.animateTo({ duration: 500 }, () => {
                  this.showEps = !this.showEps
                  PicState.foregroundBlurMode = true
                  LogUtil.info('目录', this.eps[0]?.title)
                })
              })

              Button() {
                Row() {
                  Text('下一章')
                    .fontColor($r('app.color.common_button_background_light'))
                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(25)
                    .fontColor([$r('app.color.common_button_background_light')])
                    .margin({ left: 10 })
                }
              }
              .width('34%')
              .height('100%')
              .stateEffect(false)
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .type(ButtonType.Normal)
              .enabled(this.detail?.lastReadOrder! < this.eps.length)
              .onClick(() => {
                this.goToEp(this.detail?.lastReadOrder! + 1)
                LogUtil.info(`点击下一章, this.detail?.lastReadOrder!: ${this.detail?.lastReadOrder!}`)
              })
            }
            .width('100%')
            .height(56 + PicState.bottomRectHeight)
            .backgroundColor($r('app.color.start_window_background'))
            .transition(TransitionEffect.move(TransitionEdge.BOTTOM))
          }
          .width('100%')
          .height('100%')
          .foregroundBlurStyle(PicState.foregroundBlurMode ? BlurStyle.Thin : BlurStyle.NONE)
        }

      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)

      // 章节列表
      HalfModal({
        show: this.showEps,
        view: () => {
          this.epsBuilder()
        },
        options: {
          title: {
            title: '目录',
          },
          height: SheetSize.MEDIUM,
          showClose: false,
          dragBar: false,
          preferType: SheetType.CENTER,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          onWillDismiss: () => {
            ToastUtil.animateTo({ duration: 500 }, () => {
              this.showEps = false
              PicState.foregroundBlurMode = false
            })
          },
        }
      })

      // 阅读设置
      HalfModal({
        show: this.showReadingSettings,
        view: () => {
          this.settingsBuilder()
        },
        options: {
          title: {
            title: '阅读设置',
          },
          height: SheetSize.MEDIUM,
          showClose: false,
          dragBar: false,
          preferType: SheetType.CENTER,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          onWillDismiss: () => {
            ToastUtil.animateTo({ duration: 500 }, () => {
              this.showReadingSettings = false
              PicState.foregroundBlurMode = false
            })
          },
        }
      })

    }
    .mode(NavDestinationMode.STANDARD)
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.detail = context.pathInfo.param as ComicDetailInfo
      this.load(this.detail.lastReadIndex)
      this.loadEps(1)
      console.log(`阅读 ${this.detail.title} 第${this.detail.lastReadOrder}章 index: ${this.detail.lastReadIndex}`)
      // 进入沉浸模式
      this.showSystemBar(false)
      // 应用阅读设置
      this.setKeepScreenOn(PreferenceManager.reader_keep_screen_on)
      if (PreferenceManager.reader_brightness >= 0) {
        this.setReaderBrightness(PreferenceManager.reader_brightness)
      }
    })
    .onDisAppear(async () => {
      // 退出沉浸模式
      this.showSystemBar(true)
      // 还原窗口设置（常亮与亮度仅在阅读期间生效）
      this.setKeepScreenOn(false)
      this.setReaderBrightness(-1)
    })
    .onBackPressed(() => {
      LogUtil.info('返回了')
      if (this.showToolbar) {
        LogUtil.info(`this.showToolbar ${this.showToolbar}`)
        ToastUtil.animateTo({ duration: 300 }, () => {
          this.showToolbar = false
        })
        return true
      } else {
        return false
      }
    })
  }

  /**
   * 右侧设置按钮
   */
  @Builder
  rightBuilder() {
    Row() {
      SymbolGlyph($r('sys.symbol.gearshape_fill'))
        .fontSize(24)
        .fontColor([$r('app.color.common_button_background_light')])
    }
    .onClick(() => {
      PicState.foregroundBlurMode = true
      this.showReadingSettings = true
    })
  }

  @Builder
  settingsBuilder() {
    Column({ space: 6 }) {
      // 亮度
      Row() {
        Text('阅读亮度')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
        Blank()
        Text(PreferenceManager.reader_brightness < 0 ? '跟随系统' :
          `${Math.round(this.readerBrightness * 100)}%`)
          .fontSize(13)
          .fontColor($r('sys.color.font_secondary'))
        if (PreferenceManager.reader_brightness >= 0) {
          Text('恢复系统亮度')
            .fontSize(13)
            .fontColor($r('app.color.custom_pink'))
            .margin({ left: 12 })
            .onClick(() => {
              PreferenceManager.reader_brightness = -1
              this.readerBrightness = 0.5
              this.setReaderBrightness(-1)
            })
        }
      }
      .width('100%')
      .height(40)

      // 亮度轨道（自绘：内置 Slider 的拖拽手势会被半模态吞掉，只剩点击跳变）
      Stack({ alignContent: Alignment.Center }) {
        // 轨道与已选部分
        Row() {
          Row()
            .width(`${this.readerBrightness * 100}%`)
            .height(4)
            .backgroundColor($r('app.color.custom_pink'))
        }
        .width('100%')
        .height(4)
        .borderRadius(2)
        .backgroundColor($r('app.color.custom_gray'))

        // 滑块
        Circle({ width: 22, height: 22 })
          .fill($r('app.color.custom_pink'))
          .translate({
            x: this.brightnessBarWidth > 22 ?
            (this.readerBrightness - 0.5) * (this.brightnessBarWidth - 22) : 0
          })
      }
      .width('100%')
      .height(36)
      .onAreaChange((oldArea: Area, newArea: Area) => {
        this.brightnessBarWidth = newArea.width as number
        this.brightnessBarX = (newArea.globalPosition.x ?? 0) as number
      })
      .gesture(GestureGroup(GestureMode.Exclusive,
        PanGesture({ fingers: 1 })
          .onActionStart((e: GestureEvent | undefined) => {
            this.updateBrightnessFromGesture(e)
          })
          .onActionUpdate((e: GestureEvent | undefined) => {
            this.updateBrightnessFromGesture(e)
          })
          .onActionEnd(() => {
            PreferenceManager.reader_brightness = this.readerBrightness
          }),
        TapGesture({ count: 1, fingers: 1 })
          .onAction((e: GestureEvent) => {
            this.updateBrightnessFromGesture(e)
            PreferenceManager.reader_brightness = this.readerBrightness
          })
      ))

      Divider().color($r('app.color.custom_gray'))

      // 点击翻页
      Row() {
        Text('点击翻页')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: PreferenceManager.reader_tap_paging })
          .selectedColor($r('app.color.custom_pink'))
          .onChange((isOn: boolean) => {
            PreferenceManager.reader_tap_paging = isOn
          })
      }
      .width('100%')
      .height(46)

      // 屏幕常亮
      Row() {
        Text('屏幕常亮')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: PreferenceManager.reader_keep_screen_on })
          .selectedColor($r('app.color.custom_pink'))
          .onChange((isOn: boolean) => {
            PreferenceManager.reader_keep_screen_on = isOn
            this.setKeepScreenOn(isOn)
          })
      }
      .width('100%')
      .height(46)

      // 隐私模式
      Row() {
        Text('隐私模式')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: PreferenceManager.privacy_mode })
          .selectedColor($r('app.color.custom_pink'))
          .onChange((isOn: boolean) => {
            PreferenceManager.privacy_mode = isOn
          })
      }
      .width('100%')
      .height(46)

      Divider().color($r('app.color.custom_gray'))

      // 深浅色
      Row() {
        Text('深浅色')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
        Blank()
        Row({ space: 8 }) {
          ForEach(AppConstants.ColorModeItems, (item: PreferenceItem) => {
            Text(item.name)
              .fontSize(13)
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .borderRadius(14)
              .backgroundColor(PreferenceManager.color_mode === item.key ?
              $r('app.color.custom_pink') : $r('app.color.custom_gray'))
              .fontColor(PreferenceManager.color_mode === item.key ? Color.White : $r('sys.color.font_primary'))
              .onClick(() => {
                PreferenceManager.color_mode = item.key
                ColorModeManager.switchColorMode(_PicState.Context, item.key)
              })
          })
        }
      }
      .width('100%')
      .height(46)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .margin({ bottom: PicState.bottomRectHeight })
  }

  /**
   * 章节列表
   */
  @Builder
  epsBuilder() {
    Column() {
      List({ scroller: new Scroller() }) {
        ForEach(this.eps.reverse(), (ep: ComicEp) => {
          ListItem() {
            Text(ep.title)
              .width('100%')
              .height(50)
              .minFontSize(16)
              .maxFontSize(20)
              .maxLines(1)
              .fontColor(this.detail?.lastReadOrder! === ep.order ? $r('app.color.common_button_background_weight') :
              Color.Black)
              .fontWeight(this.detail?.lastReadOrder! === ep.order ? FontWeight.Bold : FontWeight.Normal)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .heightAdaptivePolicy(TextHeightAdaptivePolicy.MAX_LINES_FIRST)
              .onClick(() => {
                this.goToEp(ep.order)
              })
          }
          .width('100%')
          .height(50)
          .margin({ left: 20, right: 20 })
        })
      }
      .width('100%')
      .height('100%')
      .divider({
        strokeWidth: 1,
        color: $r('app.color.custom_gray'),
        startMargin: 20,
        endMargin: 20
      })
    }
    .width('100%')
    .margin({ bottom: PicState.bottomRectHeight })
  }

  aboutToAppear(): void {
    hilog.info(0x0000, 'PicaWindowLog#ComicReader', '窗口新高度：%{public}d 新宽度：%{public}i', PicState.windowWidth, PicState.windowHeight)
  }

  async aboutToDisappear(): Promise<void> {

  }

  load(index?: number) {
    chapter(this.detail?._id!, this.detail?.lastReadOrder!, this.page).then(res => {
      ToastUtil.animateTo({ duration: 200 }, () => {
        this.title = res.ep.title
        this.maxPage = res.pages.pages
        res.pages.docs.forEach((c, i) => {
          this.images.push(`${PreferenceManager.image_api}${c.media.path}`)
        })
        // 记录待恢复的页码（仅首次进入时的初始加载会传入）
        if (index && index > 0) {
          this.pendingRestore = index
        }
        // 恢复目标页还未加载到（章节图片分页返回），先继续拉取下一页
        if (this.pendingRestore >= 0 && this.pendingRestore >= this.images.length && this.page < this.maxPage) {
          this.page++
          this.load()
          return
        }
        if (this.pendingRestore >= 0) {
          const target = Math.min(this.pendingRestore, this.images.length - 1)
          this.pendingRestore = -1
          this.currentImageIndex = target
          // 新插入的 item 布局完成前 scrollToIndex 不生效（animateTo 闭包内同步调用为 no-op），延迟到布局后再跳转；
          // 跳转落地前保持 canSaveHistory=false，防止初始布局回调把进度抹回 0
          setTimeout(() => {
            this.scroll.scrollToIndex(target, false)
            this.canSaveHistory = true
            LogUtil.info(`阅读进度恢复至第${target + 1}张`)
          }, 100)
        } else {
          // 无恢复任务（首次进度为 0 / 翻页加载 / 切章），加载完成即可正常保存
          this.canSaveHistory = true
        }
        console.log(`初始加载，总共：${this.images.length}页，请求恢复至：${index}`)
      })
    })
  }

  loadEps(page: number) {
    eps(this.detail?._id!, page).then(res => {
      ToastUtil.animateTo({ duration: 300 }, () => {
        this.eps.push(...res.eps.docs)
        if (page < res.eps.pages) {
          LogUtil.info(`递归加载所有章节：${page + 1}-${res.eps.pages}`)
          this.loadEps(page + 1)
        } else {
          LogUtil.info(`所有章节加载结束：${this.eps.length}`)
          this.eps = this.eps.reverse()
        }
      })
    })
  }

  /**
   * 根据手势位置换算亮度值（实时预览）
   */
  private updateBrightnessFromGesture(e: GestureEvent | undefined) {
    if (!e || this.brightnessBarWidth <= 0) {
      return
    }
    const x = e.fingerList[0].globalX - this.brightnessBarX
    const value = Math.min(Math.max(x / this.brightnessBarWidth, 0.05), 1)
    this.readerBrightness = value
    this.setReaderBrightness(value)
  }

  /**
   * 阅读时保持屏幕常亮
   */
  setKeepScreenOn(keep: boolean) {
    try {
      const windowClass: window.Window = AppUtil.getContext().windowStage.getMainWindowSync()
      windowClass.setWindowKeepScreenOn(keep).catch(() => {
        LogUtil.error(`设置屏幕常亮 ${keep} 失败`)
      })
    } catch (error) {
      LogUtil.error(`windowClass获取失败，code: ${error.code}, messae: ${error.message}`)
    }
  }

  /**
   * 设置阅读亮度，-1 表示跟随系统
   */
  setReaderBrightness(value: number) {
    try {
      const windowClass: window.Window = AppUtil.getContext().windowStage.getMainWindowSync()
      windowClass.setWindowBrightness(value).catch(() => {
        LogUtil.error(`设置阅读亮度 ${value} 失败`)
      })
    } catch (error) {
      LogUtil.error(`windowClass获取失败，code: ${error.code}, messae: ${error.message}`)
    }
  }

  showSystemBar(show: boolean) {
    try {
      let windowClass: window.Window = AppUtil.getContext().windowStage.getMainWindowSync()
      windowClass.setSpecificSystemBarEnabled('status', show, true).catch(() => {
        LogUtil.error(`设置status ${show} 失败`)
      })
      windowClass.setSpecificSystemBarEnabled('navigation', show, true).catch(() => {
        LogUtil.error(`设置navigation ${show} 失败`)
      })
      windowClass.setSpecificSystemBarEnabled('navigationIndicator', show, true).catch(() => {
        LogUtil.error(`设置navigationIndicator ${show} 失败`)
      })
    } catch (error) {
      LogUtil.error(`windowClass获取失败，code: ${error.code}, messae: ${error.message}`)
    }
  }

  goToEp(order: number) {
    this.pendingRestore = -1
    this.disappear = this.detail?.lastReadOrder! < order ? TransitionEffect.move(TransitionEdge.START) :
    TransitionEffect.move(TransitionEdge.END)
    ToastUtil.animateTo({ duration: 500 }, () => {
      if (this.detail) {
        this.scroll.scrollToIndex(0, true)
        this.detail.lastReadOrder = order
        this.page = 1
        this.maxPage = 1
        this.images = []
        this.load()
        // this.eps = []
        // this.loadEps(1)
      }
    })
  }

}
