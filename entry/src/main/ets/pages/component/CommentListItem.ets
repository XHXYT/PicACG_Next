import { ImageKnifeComponent } from '@ohos/imageknifepro'
import { DateUtil } from '@pura/harmony-utils'
import CommentList from './CommentList'
import HalfModal from './HalfModal'
import { ComicCardInterface } from '../../common/Model'


@ComponentV2
export default struct CommentListItem {

  @Param _id: string = ''
  @Param content: string = ''
  @Param likesCount: number = 0
  @Param isLiked: boolean = false
  @Param commentsCount: number = 0
  @Param created_at: string = '' // 对应 Comment.created_at

  // 关联数据
  @Param comicTitle: string = '' // 对应 Comment._comic.title
  @Param comicId: string = ''    // 对应 Comment._comic._id
  @Param avatar: string = ''     // 处理后的头像路径
  @Param name: string = ''       // 对应 Comment._user.name

  // 内部 UI 状态
  @Local showInComments: boolean = false

  // 事件暴露
  @Event onLike: (id: string, isLike: boolean) => void = () => {}
  @Event onComicClick: (comic: ComicCardInterface) => void = () => {}

  build() {
    Row() {
      // 头像
      Column() {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.avatar,
            border: { radius: 50, width: 2, color: $r('app.color.custom_pink') }
          }
        })
          .width(60)
          .height(60)
      }
      .width(72)
      .height(72)
      .padding({ left: 8, top: 8 })
      .margin({ right: 14 })

      // 评论信息
      Column() {
        // 昵称 + 评论时间
        Row() {
          Text(this.name)
            .width('50%')
            .maxLines(1)
            .minFontSize(10)
            .fontWeight(FontWeight.Bold)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)

          Text(DateUtil.getTipDateStr(new Date(this.created_at)))
            .width('50%')
            .maxLines(1)
            .minFontSize(10)
            .maxFontSize(14)
            .fontColor(Color.Gray)
            .textAlign(TextAlign.End)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
        }
        .padding({ right: 20 })

        // 评论内容
        Row() {
          Text(this.content)
            .width('100%')
            .padding({ right: 20 })
        }
        .margin({ top: 5, bottom: 10 })

        // 操作按钮
        Row() {
          // 喜欢
          Row() {
            Image($r('app.media.ic_public_heart'))
              .width(14)
              .fillColor(this.isLiked ? $r('app.color.custom_pink') : undefined)
            Text(`${this.likesCount}`)
              .fontSize(14)
              .margin({ left: 5 })
          }
          .onClick(() => {
            this.onLike(this._id, this.isLiked)
          })

          // 楼中楼 (显示评论数)
          if (this.commentsCount >= 0) {
            Row() {
              Image($r('app.media.ic_public_comments'))
                .width(13)
              Text(`${this.commentsCount}`)
                .fontSize(14)
                .margin({ left: 5 })
            }
            .margin({ left: 15 })
            .onClick(() => {
              this.showInComments = this.commentsCount > 0
            })
          }
        }
        .width('100%')

        // 漫画链接 (如果是评论列表)
        if (this.comicId && this.comicTitle) {
          Row() {
            Text(`>>> ${this.comicTitle}`)
              .width('100%')
              .fontColor($r('app.color.common_button_background_light'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                this.onComicClick({
                  id: this.comicId,
                  title: this.comicTitle,
                  image: ''
                })
              })
          }
          .width('100%')
        }
      }
      .width('100%')
      .constraintSize({ minHeight: 100, maxHeight: '100%' })
      .padding({ bottom: 10 })
      .layoutWeight(1)

      HalfModal({
        show: this.showInComments,
        view: () => { this.inComments() },
        options: {
          title: { title: '回复', subtitle: this.content },
          height: SheetSize.MEDIUM,
          showClose: false,
          dragBar: false,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          onDisappear: () => { this.showInComments = false },
        }
      })
    }
    .width('100%')
    .constraintSize({ minHeight: 100, maxHeight: '100%' })
    .padding({ top: 10 })
    .layoutWeight(1)
  }

  @Builder inComments() {
    CommentList({
      commentId: this._id,
      onComicClick: (comic) => {
        this.onComicClick(comic)
      }
    })
  }

}
