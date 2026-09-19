import { comments, commentsChildren, replyComment, sendComment, likeComment } from '../../api/comic';
import { myComments } from '../../api/profile';
import { Comment } from '../../api/models';
import { CommentResponse, ComicActionResponse } from '../../api/profile';
import { ToastUtil } from '../../utils/ToastUtils';
import CommentListItem from './CommentListItem';
import { LogUtil } from '@pura/harmony-utils';
import { ComicCardInterface } from '../../common/Model';
import { buildImageUrl } from '../../common/Consts';
import { homeVM } from '../../viewmodel/HomeViewModel';


@ObservedV2
class CommentListViewModel {
  @Trace comments: Comment[] = [];
  @Trace topComments: Comment[] = [];
  @Trace isLoading: boolean = false;
  @Trace isRefreshing: boolean = true;
  @Trace canReply: boolean = false;

  private page: number = 1;
  private maxPage: number = 1;
  private comicId: string = '';
  private commentId: string = '';

  init(comicId: string, commentId: string) {
    this.comicId = comicId;
    this.commentId = commentId;
    this.loadComments();
  }

  async refresh() {
    this.page = 1;
    await this.loadComments();
  }

  async loadMore() {
    if (this.isLoading || this.page >= this.maxPage) return;
    this.page++;
    await this.loadComments();
  }

  private async loadComments() {
    this.isLoading = true;

    try {
      let res: CommentResponse;

      // 根据 ID 判断使用哪个 API (严格遵循 comic.ets 和 profile.ets 的定义)
      if (this.commentId) {
        // 楼中楼： -> Promise<CommentResponse>
        res = await commentsChildren(this.page, this.commentId);
        this.canReply = true;
      } else if (this.comicId) {
        // 漫画评论： -> Promise<CommentResponse>
        res = await comments(this.page, this.comicId);
        this.canReply = true;
      } else {
        // 我的评论：(page) => Promise<CommentResponse>
        res = await myComments(this.page);
        this.canReply = false;
      }

      // 处理 PicaPage 分页数据
      const pager = res.comments;
      if (this.page === 1) {
        this.comments = pager.docs || [];
        this.topComments = res.topComments || [];
      } else {
        this.comments = [...this.comments, ...pager.docs];
      }

      this.page = pager.page;
      this.maxPage = pager.pages;

    } catch (e) {
      LogUtil.error('Load comments failed: ' + JSON.stringify(e));
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  async postComment(content: string): Promise<boolean> {
    if (!content) return false;
    try {
      if (this.commentId) {
        // 回复楼中楼： {
        await replyComment(this.commentId, content);
      } else if (this.comicId) {
        // 发表评论： {
        await sendComment(this.comicId, content);
      }
      ToastUtil.showToast({ message: '评论成功' });
      // 新评论会出现在"我的评论"列表中，标脏等待其可见时刷新
      homeVM.markCommentDirty();
      await this.refresh();
      return true;
    } catch (e) {
      ToastUtil.showToast({ message: '评论失败' });
      return false;
    }
  }

  async toggleLike(commentId: string, isCurrentlyLiked: boolean): Promise<void> {
    try {
      // 调用点赞 API，返回 ComicActionResponse
      const res: ComicActionResponse = await likeComment(commentId);
      // 根据返回的 action 判断状态
      if (res.action === 'like') {
        ToastUtil.showToast({ message: '喜欢成功' });
        this.updateCommentLikeStatus(commentId, true, 1);
      } else {
        // 'unlike'
        ToastUtil.showToast({ message: '取消喜欢成功' });
        this.updateCommentLikeStatus(commentId, false, -1);
      }
    } catch (e) {
      LogUtil.error('Like failed');
    }
  }

  private updateCommentLikeStatus(id: string, isLike: boolean, countDelta: number) {
    const updateList = (list: Comment[]): boolean => {
      const index = list.findIndex(c => c._id === id);
      if (index !== -1) {
        const oldItem = list[index];
        // 创建新对象以触发 @Trace 更新
        const newItem: Comment = {
          isLiked: isLike,
          likesCount: oldItem.likesCount + countDelta,
          id: oldItem.id,
          content: oldItem.content,
          hide: oldItem.hide,
          created_at: oldItem.created_at,
          totalComments: oldItem.totalComments,
          commentsCount: oldItem.commentsCount,
          isTop: oldItem.isTop,
          _id: oldItem._id,
          _comic: oldItem._comic,
          _user: oldItem._user
        };

        // 替换数组元素以触发更新
        const newList = [...list];
        newList[index] = newItem;

        if (list === this.comments) {
          this.comments = newList;
        } else {
          this.topComments = newList;
        }
        return true;
      }
      return false;
    };

    // 先在置顶里找，找不到再去普通列表
    if (!updateList(this.topComments)) {
      updateList(this.comments);
    }
  }
}

@ComponentV2
export default struct CommentList {

  @Param comicId: string = ''
  @Param commentId: string = ''
  @Param avatar: string | undefined = undefined
  @Param refreshTick: number = 0    // 刷新信号

  @Local viewModel: CommentListViewModel = new CommentListViewModel()
  @Local inputContent: string = '';

  @Event onComicClick: (comic: ComicCardInterface) => void = () => {}

  private scroll: Scroller = new Scroller()

  aboutToAppear(): void {
    this.viewModel.init(this.comicId, this.commentId);
  }

  // tick 变化时刷新数据
  @Monitor('refreshTick')
  onRefreshTickChange(): void {
    // 回到列表顶部，避免刷新后停在底部旧位置
    this.scroll.scrollTo({ xOffset: 0, yOffset: 0 })
    this.viewModel.refresh()
  }

  build() {
    Column() {
      Refresh({ refreshing: $$this.viewModel.isRefreshing }) {
        List({ space: 5, scroller: this.scroll }) {

          // 置顶评论
          Repeat<Comment>(this.viewModel.topComments)
            .key((item: Comment) => item._id)
            .each((obj: RepeatItem<Comment>) => {
              ListItem() {
                this.CommentItemBuilder(obj.item, true)
              }
              .borderWidth(1)
              .borderRadius(10)
              .borderColor($r('app.color.custom_pink'))
            })

          // 普通评论
          Repeat<Comment>(this.viewModel.comments)
            .key((item: Comment) => item._id)
            .each((obj: RepeatItem<Comment>) => {
              ListItem() {
                this.CommentItemBuilder(obj.item, false)
              }
            })

          if (this.viewModel.isLoading) {
            ListItem() {
              Row() { LoadingProgress().height(32).width(48) }
              .width('100%')
              .height(64)
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .width('100%')
        .height('100%')
        .divider({ strokeWidth: 1, color: $r('app.color.custom_gray'), startMargin: 20, endMargin: 20 })
        .scrollBar(BarState.Off)
        .onScrollIndex((_: number, end: number) => {
          if (end + 5 >= this.viewModel.comments.length) {
            this.viewModel.loadMore();
          }
        })
      }
      .layoutWeight(1)
      .refreshOffset(64)
      .pullToRefresh(true)
      .onRefreshing(() => {
        this.viewModel.refresh();
      })

      if (this.viewModel.canReply) {
        Column() {
          TextInput({ text: this.inputContent, placeholder: '发表你的观点吧!' })
            .width('100%')
            .height(50)
            .margin({ top: 10, bottom: 10 })
            .onChange((value: string) => { this.inputContent = value })
            .onSubmit(() => { this.doComment() })

          Button('回复')
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.custom_pink'))
            .onClick(() => { this.doComment() })
        }
        .width('100%')
        .transition(TransitionEffect.scale({ x: 0.9, y: 0.9 }))
      }
    }
    .layoutWeight(1)
    .padding({ left: 10, right: 10 })
  }

  @Builder
  CommentItemBuilder(comment: Comment, isTop: boolean) {
    CommentListItem({
      _id: comment._id,
      content: comment.content,
      isLiked: comment.isLiked,
      likesCount: comment.likesCount,
      commentsCount: comment.commentsCount,
      created_at: comment.created_at,
      // 映射嵌套对象
      comicTitle: comment._comic?.title ?? '',
      comicId: comment._comic?._id ?? '',
      // 优先使用传入的 avatar (如有)，否则使用评论用户的头像
      avatar: this.avatar ?? (comment._user?.avatar ? buildImageUrl(comment._user.avatar) : ''),
      name: comment._user?.name ?? '',
      onLike: (id) => {
        this.viewModel.toggleLike(id, comment.isLiked);
      },
      onComicClick: (comic) => {
        this.onComicClick(comic)
      }
    })
      .layoutWeight(1)
      .transition(TransitionEffect.asymmetric(
        TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 300 }),
        TransitionEffect.move(TransitionEdge.START).animation({ duration: 300 })
      ))
  }

  doComment() {
    if (!this.inputContent) return;
    this.viewModel.postComment(this.inputContent).then(success => {
      if (success) this.inputContent = '';
    });
  }

}
