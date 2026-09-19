import { PicState } from '../../entryability/AppState'
import CommentList from '../component/CommentList'
import { TitleBar } from '../component/TitleBar'

@Builder
export function CommentsBuilder(name: string, param: Object) {
  Comments()
}

/**
 * 哔咔留言板
 */
@Component
export default struct Comments {

  private pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column() {
        TitleBar({
          title: '哔咔留言板',
        })
        CommentList({
          comicId: '5822a6e3ad7ede654696e482',
          onComicClick: (comic) => {
            this.pageInfos.pushPathByName('comic_detail', comic)
          }
        })
          .margin({ top: 10 })
          .layoutWeight(1)
      }
      .height('100%')
      .width('100%')
      .padding({
        top: PicState.topRectHeight,
        bottom: PicState.bottomRectHeight,
        left: 10,
        right: 10
      })
    }.backgroundColor($r('app.color.start_window_background'))
    .mode(NavDestinationMode.STANDARD)
    .hideTitleBar(true)
    .onReady((ctx) => {
      this.pageInfos = ctx.pathStack
    })
  }

}