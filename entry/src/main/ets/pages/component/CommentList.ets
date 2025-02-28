import { LogUtil } from '@pura/harmony-utils';
import { comments, commentsChildren, replyComment, sendComment } from '../../api/comic';
import { Comment } from '../../api/models';
import { CommentResponse, myComments } from '../../api/profile';
import CommentListItem from './CommentListItem';
import { promptAction } from '@kit.ArkUI';

@Component
export default struct CommentList {
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @State comments: Comment[] = []
  @State topComments: Comment[] = []
  @State isRefreshing: boolean = true
  @State isLoading: boolean = false;
  @State isEnd: boolean = false;
  @State maxPage: number = 1
  @State total: number = 0
  @State page: number = 1
  @State content: string = ''
  @State showReply: boolean = false
  @Prop avatar: string | undefined = undefined
  @Prop comicId: string
  @Prop commentId: string
  private scroll: Scroller = new Scroller()

  loadComments() {
    let api: (page: number, id?: string) => Promise<CommentResponse>
    if (this.commentId) {
      LogUtil.info('加载楼中楼', this.comicId)
      api = commentsChildren as (page: number, commentId?: string) => Promise<CommentResponse>
      this.showReply = true
    } else if (this.comicId) {
      LogUtil.info('加载漫画评论', this.comicId)
      api = comments as (page: number, comicId?: string) => Promise<CommentResponse>
      this.showReply = true
    } else {
      LogUtil.info('加载我的评论')
      api = myComments
    }
    api(this.page, this.commentId ? this.commentId : this.comicId)
      .then(res => {
        animateTo({ duration: 500 }, () => {
          if (this.page === 1) {
            this.comments = res.comments.docs
            this.topComments = res.topComments
          } else {
            this.comments.push(...res.comments.docs)
          }
          this.page = res.comments.page
          this.maxPage = res.comments.pages
        })
      })
      .finally(() => {
        animateTo({ duration: 500 }, () => {
          this.isRefreshing = false
          this.isLoading = false
        })
      })
  }

  build() {
    Column() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        List({ space: 5, scroller: this.scroll }) {
          ForEach(this.topComments, (comment: Comment) => {
            ListItem() {
              CommentListItem({
                _id: comment._id,
                content: comment.content,
                isLike: comment.isLiked,
                likesCount: comment.likesCount,
                commentsCount: comment.commentsCount,
                createTime: comment.created_at,
                comicTitle: comment._comic.title,
                comicId: comment._comic._id,
                avatar: `${this.avatar ? this.avatar : comment._user?.avatar?.path}`
              })
            }
            .layoutWeight(1)
            .transition(TransitionEffect.asymmetric(
              TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 300 }),
              TransitionEffect.move(TransitionEdge.START).animation({ duration: 300 })
            ))
            .borderWidth(1)
            .borderRadius(10)
            .borderColor($r('app.color.custom_pink'))
          }, (item: Comment) => {
            return item._id
          })

          ForEach(this.comments, (comment: Comment) => {
            ListItem() {
              CommentListItem({
                _id: comment._id,
                content: comment.content,
                isLike: comment.isLiked,
                likesCount: comment.likesCount,
                commentsCount: comment.commentsCount,
                createTime: comment.created_at,
                comicTitle: comment._comic.title,
                comicId: comment._comic._id,
                avatar: `${this.avatar ? this.avatar : comment._user?.avatar?.path}`
              })
            }
            .layoutWeight(1)
            .transition(TransitionEffect.asymmetric(
              TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 300 }),
              TransitionEffect.move(TransitionEdge.START).animation({ duration: 300 })
            ))
          }, (item: Comment) => {
            return item._id
          })

          if (this.comments.length === this.total) {
            ListItem() {
              Row() {
                Text('没有更多了')
              }.width('100%')
              .height(64)
              .justifyContent(FlexAlign.Center)
            }
          }

          if (this.isLoading) {
            ListItem() {
              Row() {
                LoadingProgress().height(32).width(48)
              }.width('100%')
              .height(64)
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .width('100%')
        .height('100%')
        .divider({
          strokeWidth: 1,
          color: $r('app.color.custom_gray'),
          startMargin: 20,
          endMargin: 20
        })
        .scrollBar(BarState.Off)
        .onScrollIndex((_: number, end: number) => {
          this.isEnd = end + 5 >= this.comments.length
          if (this.isEnd && this.page < this.maxPage) {
            LogUtil.info('onReachEnd到底辣！！！要加载更多')
            this.page++
            animateTo({ duration: 500 }, () => {
              this.isLoading = true
              this.loadComments()
            })
          }
        })
      }
      .layoutWeight(1)
      .refreshOffset(64)
      .pullToRefresh(true)
      .onRefreshing(() => {
        LogUtil.info('刷新！！！！')
        this.page = 1
        animateTo({ duration: 500 }, () => {
          this.loadComments()
        })
      })

      if (this.showReply) {
        Column() {
          TextInput({
            text: this.content,
            placeholder: '发表你的观点吧!',
          })
            .width('100%')
            .height(50)
            .margin({ top: 10, bottom: 10 })
            .onChange((value: string) => {
              this.content = value
            })
            .onSubmit(() => {
              this.doComment()
            })
          Button('回复')
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.custom_pink'))
            .onClick(() => {
              this.doComment()
            })
        }
        .width('100%')
        .transition(TransitionEffect.scale({ x: 0.9, y: 0.9 }))
      }
    }
    .layoutWeight(1)
    .padding({ left: 10, right: 10 })
  }

  doComment() {
    if (this.commentId) {
      replyComment(this.commentId, this.content).then(() => {
        this.content = ''
        promptAction.showToast({ message: '评论成功', });
      })
    } else if (this.comicId) {
      sendComment(this.comicId, this.content).then(() => {
        this.content = ''
        promptAction.showToast({ message: '评论成功', });
      })
    }
  }
}