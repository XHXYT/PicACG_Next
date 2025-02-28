import CommentList from '../component/CommentList'
import { BackType, TitleBar, TitleType } from '../component/TitleBar'

@Builder
export function CommentsBuilder(name: string, param: Object) {
  Comments()
}

/**
 * 哔咔留言板
 */
@Component
export default struct Comments {
  // 状态栏高度
  @StorageProp('topRectHeight') topRectHeight: number = 0
  // 导航栏高度
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @Consume('pageStack') pageStack: NavPathStack

  build() {
    NavDestination() {
      Column() {
        TitleBar({
          titleBarColor: $r('app.color.start_window_background'),
          statusBarColor: $r('app.color.start_window_background'),
          centerLeftPadding: 60,
          centerType: TitleType.TEXT,
          centerText: '哔咔留言板',
          centerTextColor: $r('app.color.common_button_background_light'),
          leftBackType: BackType.NONE,
          leftBackFillColor: $r('app.color.common_button_background_light'),
          leftOnClick: () => {
            this.pageStack.pop()
          },
        })
        CommentList({ comicId: '5822a6e3ad7ede654696e482' })
          .margin({ top: 10 })
          .layoutWeight(1)
      }
      .height('100%')
      .width('100%')
      .padding({
        top: this.topRectHeight,
        bottom: this.bottomRectHeight,
        left: 10,
        right: 10
      })
    }.backgroundColor($r('app.color.start_window_background'))
    .mode(NavDestinationMode.STANDARD)
    .hideTitleBar(true)
  }
}