import { LogUtil, RandomUtil } from '@pura/harmony-utils';
import { StorageKey } from '../../common/Consts';
import { BackType, TitleBar, TitleType } from '../component/TitleBar';
import { ComicListOptions, SearchType } from './Comics';
import { Chip, ChipSize } from '@ohos.arkui.advanced.Chip';
import { LengthUnit } from '@kit.ArkUI';
import { keywords } from '../../api/comic';

@Builder
export function ComicSearchBuilder(name: string, param: Object) {
  ComicSearch()
}

@Component
export default struct ComicSearch {
  // 状态栏高度
  @StorageProp('topRectHeight') topRectHeight: number = 0
  // 导航条高度
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @StorageProp(StorageKey.KEYWORDS) keywords: string[] = []
  @StorageLink(StorageKey.SEARCH_HISTORY) searchHistory: string[] = []
  @Consume('pageStack') pageStack: NavPathStack
  @State refreshRotateAngle: number = 0
  @State placeholder: string = ''


  aboutToAppear(): void {
    this.placeholder = this.keywords[RandomUtil.getRandomNumber(0, this.keywords.length)]
  }

  build() {
    NavDestination() {
      // 搜索栏
      TitleBar({
        titleBarColor: Color.White,
        statusBarColor: Color.White,
        leftBackType: BackType.NONE,
        leftBackFillColor: $r('app.color.common_button_background_light'),
        leftOnClick: () => {
          this.pageStack.pop()
        },
        centerLeftPadding: 50,
        centerType: TitleType.SEARCH,
        searchPlaceholder: this.placeholder,
        searchButtonText: "搜索",
        searchButtonOptions: {
          fontColor: $r('app.color.common_button_background_light')
        },
        onSubmitSearch: (value) => {
          this.goToSearch(value)
        },
        titleBarRightPadding: 20
      })
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
                  this.keywords = res.keywords
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
            ForEach(this.keywords, (key: string) => {
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
        bottom: this.bottomRectHeight,
        left: 10,
        right: 10
      })

    }.width('100%').height('100%')
    .mode(NavDestinationMode.STANDARD)
    .hideTitleBar(true)
    .padding({
      top: this.topRectHeight
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
    this.pageStack.pushPathByName('Comics', { type: SearchType.Custom, key: key } as ComicListOptions)
  }
}