import { ImageKnifeComponent } from '@ohos/imageknife'
import { DateUtil } from '@pura/harmony-utils'
import { likeComment } from '../../api/comic'
import { PreferenceStorageKey } from '../../utils/Preference'
import { ComicCardInterface } from './ComicCard'
import { promptAction } from '@kit.ArkUI'
import CommentList from './CommentList'
import HalfModal from './HalfModal'

@Component
export default struct CommentListItem {
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
  @Consume('pageStack') pageStack: NavPathStack;
  @Prop _id: string
  @Prop content: string
  @Prop likesCount: number
  @Prop isLike: boolean
  @Prop commentsCount: number
  @Prop createTime: string
  @Prop comicTitle: string
  @Prop comicId: string
  @Prop avatar: string
  @Prop name: string = ''
  @Prop slogan: string
  @State showInComments: boolean = false

  build() {
    Row() {
      // 头像
      Column() {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.imageApi + this.avatar,
            border: {
              radius: 50,
              width: 2,
              color: $r('app.color.custom_pink')
            }
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
          Text(`${this.name}`)
            .width('50%')
            .maxLines(1)
            .minFontSize(10)
            .fontWeight(FontWeight.Bold)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)

          Text(DateUtil.getTipDateStr(new Date(this.createTime)))
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
          Text(`${this.content}`)
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
              .fillColor(this.isLike ? $r('app.color.custom_pink') : undefined)
            Text(`${this.likesCount}`)
              .fontSize(14)
              .margin({ left: 5 })
          }
          .onClick(() => {
            likeComment(this._id).then(res => {
              if (res.action === 'like') {
                promptAction.showToast({ message: '喜欢成功', });
                this.isLike = true
                this.likesCount++
              } else {
                promptAction.showToast({ message: '取消喜欢成功', });
                this.isLike = false
                this.likesCount--
              }
            })
          })

          // 楼中楼
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
              if (this.commentsCount > 0) {
                this.showInComments = true
              } else {
                this.showInComments = false
              }
            })
          }
        }
        .width('100%')

        // 本子超链接
        if (this.comicId && this.comicTitle) {
          Row() {
            Text(`>>> ${this.comicTitle}`)
              .width('100%')
              .fontColor($r('app.color.common_button_background_light'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                this.pageStack.pushPath({
                  name: 'ComicDetail',
                  param: { id: this.comicId, title: this.comicTitle } as ComicCardInterface
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
        view: () => {
          this.inComments()
        },
        options: {
          title: {
            title: '回复',
            subtitle: this.content,
          },
          height: SheetSize.MEDIUM,
          showClose: false,
          dragBar: false,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          onDisappear: () => {
            this.showInComments = false
          },
        }
      })
    }
    .width('100%')
    .constraintSize({ minHeight: 100, maxHeight: '100%' })
    .padding({ top: 10 })
    .layoutWeight(1)
  }

  @Builder
  inComments() {
    CommentList({ commentId: this._id })
      .margin({ bottom: this.bottomRectHeight })
  }
}