import { LogUtil, RandomUtil } from '@pura/harmony-utils';
import { Chip, ChipSize } from '@ohos.arkui.advanced.Chip';
import { LengthUnit } from '@kit.ArkUI';
import { keywords } from '../../api/comic';
import { ComicListOptions, SearchType } from '../../common/Model'
import { PicState } from '../../entryability/AppState';


@Builder
export function ComicSearchBuilder(name: string, param: Object) {
  ComicSearch()
}


@ComponentV2
export default struct ComicSearch {

  @Local searchHistory: string[] = []
  @Local refreshRotateAngle: number = 0
  @Local placeholder: string = ''
  @Local searchText: string = ''

  private pageInfos: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.placeholder = PicState.keywords[RandomUtil.getRandomNumber(0, PicState.keywords.length)]
  }

  build() {
    NavDestination() {
      // 搜索栏
      Row({ space: 10 }) {
        // 返回按钮
        Button() {
          Image($r('app.media.ic_public_arrow_left'))
            .width(26)
            .height(26)
            .fillColor($r('sys.color.font_primary'))
        }
        .backgroundColor(Color.Transparent)
        .margin({ left: 6 })
        .onClick(() => {
          this.pageInfos.pop(true)
        })

        Search({ placeholder: this.placeholder })
          .layoutWeight(1)
          .height(40)
          .searchButton('搜索', { fontColor: $r('app.color.common_button_background_light') })
          .caretStyle({ color: $r('app.color.common_button_background_light') })
          .onChange((value: string) => {
            this.searchText = value
          })
          .onSubmit((value: string) => {
            this.goToSearch(value)
          })
      }
      .width('100%')
      .height(50)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 6, right: 12 })
      // 搜索发现 & 搜索历史
      Column() {
        Column() {
          Row() {
            Text('搜索发现')
            Button() {
              Row() {
                Image($r('app.media.ic_public_refresh'))
                  .width(14)
                  .height(14)
                  .fillColor(Color.Gray)
                  .rotate({
                    x: 0,
                    y: 0,
                    z: 1,
                    angle: this.refreshRotateAngle
                  })
                Text('刷新')
                  .fontSize(12)
                  .fontColor(Color.Gray)
              }
              .width(40)
              .height(20)
            }
            .width(40)
            .height(20)
            .margin({ left: 10 })
            .stateEffect(false)
            .type(ButtonType.Normal)
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick(() => {
              LogUtil.info('刷新大家都在搜')
              animateTo({ duration: 1000 }, () => {
                this.refreshRotateAngle += 360
                keywords().then(res => {
                  PicState.keywords = res.keywords
                })
              })
            })
          }
          .width('100%')

          Flex({
            wrap: FlexWrap.Wrap,
            space: {
              main: { value: 10, unit: LengthUnit.VP },
              cross: { value: 10, unit: LengthUnit.VP }
            }
          }) {
            ForEach(PicState.keywords, (key: string) => {
              Chip({
                label: {
                  text: key,
                  fontSize: 12
                },
                allowClose: false,
                size: ChipSize.SMALL,
                onClicked: () => this.goToSearch(key)
              })
            })
          }
          .width('100%')
          .margin({ top: 10, bottom: 20 })
        }
        .width('100%')

        if (this.searchHistory.length > 0) {
          Column() {
            Row() {
              Text('搜索历史')
              Button() {
                Row() {
                  Image($r('app.media.ic_public_delete'))
                    .width(14)
                    .height(14)
                    .fillColor(Color.Gray)
                  Text('清空')
                    .fontSize(12)
                    .fontColor(Color.Gray)
                }
                .width(40)
                .height(20)
              }
              .width(40)
              .height(20)
              .margin({ left: 10 })
              .stateEffect(false)
              .type(ButtonType.Normal)
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .onClick(() => {
                LogUtil.info('清空搜索历史')
                animateTo({ duration: 400 }, () => {
                  this.searchHistory = []
                })
              })
            }
            .width('100%')

            Flex({
              wrap: FlexWrap.Wrap,
              space: {
                main: { value: 10, unit: LengthUnit.VP },
                cross: { value: 10, unit: LengthUnit.VP }
              }
            }) {
              ForEach(this.searchHistory.reverse(), (key: string) => {
                Chip({
                  label: {
                    text: key,
                    fontSize: 12,
                    labelMargin: {
                      right: 5
                    }
                  },
                  allowClose: true,
                  size: ChipSize.SMALL,
                  onClicked: () => this.goToSearch(key),
                  onClose: () => {
                    animateTo({ duration: 400 }, () => {
                      this.searchHistory = this.searchHistory.filter(k => k !== key)
                    })
                  }
                })
              })
            }
            .width('100%')
            .margin({ top: 10, bottom: 20 })
          }
          .width('100%')
        }
      }
      .width('100%')
      .margin({ top: 15 })
      .padding({
        bottom: PicState.bottomRectHeight,
        left: 10,
        right: 10
      })

    }.width('100%').height('100%')
    .mode(NavDestinationMode.STANDARD)
    .hideTitleBar(true)
    .backgroundColor($r('app.color.start_window_background'))
    .padding({
      top: PicState.topRectHeight
    })
    .onReady((ctx) => {
      this.pageInfos = ctx.pathStack
    })
  }

  goToSearch(key: string) {
    if (!key) {
      key = this.placeholder
    }
    LogUtil.info("onSubmitSearch:" + key)
    if (this.searchHistory.indexOf(key) >= 0) {
      this.searchHistory.splice(this.searchHistory.indexOf(key), 1)
    }
    this.searchHistory.push(key)
    this.pageInfos.pushPathByName('Comics', { type: SearchType.Custom, key: key } as ComicListOptions)
  }
}