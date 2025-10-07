import { SymbolGlyphModifier, window } from '@kit.ArkUI'
import { ImageKnifeComponent, ImageKnifeRequest } from '@ohos/imageknife'
import { AppUtil, LogUtil } from '@pura/harmony-utils'
import { chapter, eps } from '../../api/comic'
import { ComicDetailInfo, ComicEp } from '../../api/models'
import { PreferenceItem, PreferenceManager, PreferenceStorageKey } from '../../utils/Preference'
import { BackType, TitleBar, TitleType } from '../component/TitleBar'
import { ImageQuality } from '../../common/Config'
import { HistoryUtil } from '../../utils/History'
import HalfModal from '../component/HalfModal'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ToastUtil } from '../../utils/ToastUtils'
import { SettingsPage } from '../Settings'

@Builder
export function ComicReaderBuilder(name: string, param: Object) {
  ComicReader()
}

@Component
export default struct ComicReader {

  // 背景模糊
  @StorageLink('foregroundBlur') foregroundBlurMode: boolean = false
  // 状态栏高度
  @StorageProp('topRectHeight') topRectHeight: number = 0
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('WindowWidth') windowWidth: number = 0
  @StorageLink('WindowHeight') windowHeight: number = 0
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
  @StorageProp(PreferenceStorageKey.IMAGE_QUALITY) imageQuality: string = ''
  @Consume('pageStack') pageStack: NavPathStack
  @State detail?: ComicDetailInfo = undefined
  // 目录
  @State eps: ComicEp[] = []
  @State page: number = 1
  @State maxPage: number = 1
  @State images: string[] = []
  @State title: string = ''
  @State isEnd: boolean = false
  @State showToolbar: boolean = false
  @State showEps: boolean = false
  @State showReadingSettings: boolean = false
  @State disappear: TransitionEffect = TransitionEffect.move(TransitionEdge.START)
  @State scaleValue: number = 1
  @State pinchValue: number = 1;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State positionX: number = 0;
  @State positionY: number = 0;
  @State currentImageIndex: number = 0
  private scroll: Scroller = new Scroller()
  private inPan: boolean = false
  private canSaveHistory = false

  build() {
    NavDestination() {
      Stack() {
        List({ scroller: this.scroll }) {
          ForEach(this.images, (img: string) => {
            ImageKnifeComponent({
              imageKnifeOption: {
                loadSrc: img,
                placeholderSrc: $r('app.media.loading'),
                objectFit: ImageFit.Auto,
                onLoadListener: {
                  onLoadFailed: (err: string, req?: ImageKnifeRequest) => {
                    LogUtil.error('图片加载失败：', err, ' - ', img)
                    LogUtil.error(JSON.stringify(req))
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
        .contentStartOffset(this.topRectHeight)
        .scrollBar(BarState.Off)
        .scale({ x: this.scaleValue, y: this.scaleValue, z: 1 })
        .offset({ x: this.offsetX, y: this.offsetY })
        .onScrollIndex((start: number, end: number) => {
          LogUtil.info(`currentIndex: ${start} - ${end}`)
          this.currentImageIndex = start
          // if (this.canSaveHistory) {
          //   HistoryUtil.setRead(this.chapter.comicId, this.chapter.order, start)
          // }
          this.isEnd = end + 5 >= this.images.length
          if (this.isEnd && this.page < this.maxPage) {
            LogUtil.info('onReachEnd到底辣！！！要加载更多')
            this.page++
            ToastUtil.animateTo({ duration: 500 }, () => {
              this.load()
            })
          }
          // 保存阅读进度
          HistoryUtil.setRead(this.detail?._id!, this.detail?.lastReadOrder!, this.currentImageIndex)
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
              const scaledWidth = this.windowWidth * this.scaleValue;
              const scaledHeight = this.windowHeight * this.scaleValue;
              // 容器的边界
              const containerLeft = 0;
              const containerRight = this.windowWidth;
              const containerTop = 0;
              const containerBottom = this.windowHeight;
              // 组件的边界（拖动后不能超过容器的范围）
              const minX = containerLeft - (scaledWidth - this.windowWidth) / 2;
              const maxX = containerRight - this.windowWidth + (scaledWidth - this.windowWidth) / 2;
              const minY = containerTop - (scaledHeight - this.windowHeight) / 2;
              const maxY = containerBottom - this.windowHeight + (scaledHeight - this.windowHeight) / 2;
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
            LogUtil.info('触发单击')
            let x = event.fingerList[0].globalX
            let y = event.fingerList[0].globalY
            if (x < this.windowWidth * 0.34 || y < this.windowHeight * 0.3) {
              LogUtil.info('点击上一页')
              ToastUtil.animateTo({ duration: 500 }, () => {
                this.scroll.scrollTo({
                  xOffset: 0,
                  yOffset: this.scroll.currentOffset().yOffset - this.windowHeight + 300,
                  animation: true
                })
              })
            } else if (x > this.windowWidth * 0.66 || y > this.windowHeight * 0.7) {
              LogUtil.info('点击下一页')
              ToastUtil.animateTo({ duration: 500 }, () => {
                this.scroll.scrollTo({
                  xOffset: 0,
                  yOffset: this.scroll.currentOffset().yOffset + this.windowHeight - 300,
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
              .height(this.topRectHeight)
              .backgroundColor($r('app.color.start_window_background'))
            TitleBar({
              titleBarColor: $r('app.color.start_window_background'),
              statusBarColor: $r('app.color.start_window_background'),
              centerType: TitleType.TEXT,
              centerText: this.title,
              centerTextColor: $r('app.color.common_button_background_light'),
              leftBackType: BackType.NONE,
              leftBackFillColor: $r('app.color.common_button_background_light'),
              leftOnClick: () => {
                this.pageStack.pop()
              },
              rightType: TitleType.CUSTOM,
              rightCustomView: () => {
                this.rightBuilder()
              },
              titleBarRightPadding: 0
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
                      this.inPan = true
                    })
                    .onActionUpdate((event: GestureEvent | undefined) => {
                      LogUtil.info(`拖动中`);
                      if (event && this.scaleValue > 1) {
                        // 动态计算缩放后的组件宽高
                        const scaledWidth = this.windowWidth * this.scaleValue;
                        const scaledHeight = this.windowHeight * this.scaleValue;
                        // 容器的边界
                        const containerLeft = 0;
                        const containerRight = this.windowWidth;
                        const containerTop = 0;
                        const containerBottom = this.windowHeight;
                        // 组件的边界（拖动后不能超过容器的范围）
                        const minX = containerLeft - (scaledWidth - this.windowWidth) / 2;
                        const maxX = containerRight - this.windowWidth + (scaledWidth - this.windowWidth) / 2;
                        const minY = containerTop - (scaledHeight - this.windowHeight) / 2;
                        const maxY = containerBottom - this.windowHeight + (scaledHeight - this.windowHeight) / 2;
                        // 更新偏移量，并限制在边界内
                        const newOffsetX = this.positionX + event.offsetX * 5;
                        const newOffsetY = this.positionY + event.offsetY * 3;

                        this.offsetX = Math.min(Math.max(newOffsetX, minX), maxX);
                        this.offsetY = Math.min(Math.max(newOffsetY, minY), maxY);
                        LogUtil.info(`正在拖动，当前偏移：${this.offsetX} ${this.offsetY}`);
                      } else if (event) {
                        // 动态计算未缩放时
                        ToastUtil.animateTo({ duration: 100 }, () => {
                          this.scroll.scrollTo({
                            xOffset: 0,
                            yOffset: this.scroll.currentOffset().yOffset + event.offsetY * 3,
                            animation: true
                          })
                        })

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
                  .onChange((value: number) => {
                    this.currentImageIndex = value
                    this.scroll.scrollToIndex(value, true)
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
                    .margin({ left: 10 })
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
                  this.foregroundBlurMode = true
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
            .height(56 + this.bottomRectHeight)
            .backgroundColor($r('app.color.start_window_background'))
            .transition(TransitionEffect.move(TransitionEdge.BOTTOM))
          }
          .width('100%')
          .height('100%')
          .foregroundBlurStyle(this.foregroundBlurMode ? BlurStyle.Thin : BlurStyle.NONE)
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
              this.foregroundBlurMode = false
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
          height: SheetSize.MEDIUM,
          showClose: false,
          dragBar: false,
          preferType: SheetType.CENTER,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          onWillDismiss: () => {
            ToastUtil.animateTo({ duration: 500 }, () => {
              this.showReadingSettings = false
              this.foregroundBlurMode = false
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
    })
    .onDisAppear(async () => {
      // 退出沉浸模式
      this.showSystemBar(true)
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
      this.foregroundBlurMode = true
      this.showReadingSettings = true
    })
  }

  @Builder
  settingsBuilder() {
    SettingsPage()
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
    .margin({ bottom: this.bottomRectHeight })
  }

  aboutToAppear(): void {
    hilog.info(0x0000, 'PicaWindowLog#ComicReader', '窗口新高度：%{public}d 新宽度：%{public}i', this.windowWidth, this.windowHeight)
  }

  async aboutToDisappear(): Promise<void> {

  }

  load(index?: number) {
    chapter(this.detail?._id!, this.detail?.lastReadOrder!, this.page).then(res => {
      ToastUtil.animateTo({ duration: 200 }, () => {
        this.title = res.ep.title
        this.maxPage = res.pages.pages
        res.pages.docs.forEach((c, i) => {
          this.images.push(`${this.imageApi}${c.media.path}`)
        })
        // 初始状态时跳转至指定页
        if (index)
          this.currentImageIndex = index
        this.scroll.scrollToIndex(this.currentImageIndex, true)
        console.log(`初始加载，总共：${this.images.length}页，跳转至：${index}`)
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
