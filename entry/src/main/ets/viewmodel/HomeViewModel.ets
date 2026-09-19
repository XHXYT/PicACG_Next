import { User, ComicSimpleInfo, ComicDetailInfo } from '../api/models';
import { favouriteAction, profile, punchIn } from '../api/profile';
import { PreferenceManager } from '../utils/preference/Settings';
import { ToastUtil } from '../utils/ToastUtils';
import { HistoryUtil } from '../utils/History';
import { PicState } from '../entryability/AppState';
import { createLogger } from '../utils/Logger';
import { buildImageUrl } from '../common/Consts';
import { accountVM } from './AccountViewModel';

const logger = createLogger('HomeViewModel')


@ObservedV2
export class HomeViewModel {
  // 用户信息
  @Trace user: User | undefined = undefined;
  @Trace avatarUrl: string = '';

  // 签到状态
  @Trace isPunched: boolean = false;

  // 刷新信号：递增触发对应列表重新加载
  @Trace readingTick: number = 0;
  @Trace historyTick: number = 0;
  @Trace favouriteTick: number = 0;
  @Trace commentTick: number = 0;
  // Home 页内部当前显示的子 Tab（0阅读记录 1浏览历史 2收藏 3评论）
  @Trace currentSubIndex: number = 0;

  // 数据变更脏标记：由数据变更点置位，列表变为可见时消费（置 false 并 tick 触发刷新）
  private dirtyReading: boolean = false;
  private dirtyHistory: boolean = false;
  private dirtyFavourite: boolean = false;
  private dirtyComment: boolean = false;

  markReadingDirty(): void {
    this.dirtyReading = true;
  }

  markHistoryDirty(): void {
    this.dirtyHistory = true;
  }

  markFavouriteDirty(): void {
    this.dirtyFavourite = true;
  }

  markCommentDirty(): void {
    this.dirtyComment = true;
  }

  /**
   * 消费指定子 Tab 的脏标记：列表变为可见时调用，脏则刷新，不脏不发多余请求
   */
  consumeDirtyAt(subIndex: number): void {
    if (subIndex === 0 && this.dirtyReading) {
      this.dirtyReading = false;
      this.readingTick++;
    } else if (subIndex === 1 && this.dirtyHistory) {
      this.dirtyHistory = false;
      this.historyTick++;
    } else if (subIndex === 2 && this.dirtyFavourite) {
      this.dirtyFavourite = false;
      this.favouriteTick++;
    } else if (subIndex === 3 && this.dirtyComment) {
      this.dirtyComment = false;
      this.commentTick++;
    }
  }

  /**
   * 加载用户信息
   */
  async loadProfile() {
    try {
      const res = await profile();
      this.user = res.user;
      this.isPunched = res.user.isPunched;
      // 拼接头像地址
      if (res.user.avatar) {
        this.avatarUrl = buildImageUrl(res.user.avatar);
      }
      // 同步昵称头像到已保存的账号记录（多账号列表展示用）
      accountVM.syncProfile(res.user);
      logger.info(`Home 个人信息加载成功`);
    } catch (e) {
      logger.error(`Home 个人信息加载失败: ${JSON.stringify(e)}`);
    }
  }

  /**
   * 打卡/签到
   */
  async doPunchIn() {
    try {
      await punchIn();
      ToastUtil.showToast({ message: '签到成功' });
      // 刷新用户信息以更新签到状态
      await this.loadProfile();
    } catch (e) {
      ToastUtil.showToast({ message: '签到失败' });
    }
  }

  /**
   * 删除浏览历史
   */
  async deleteHistory(comic: ComicSimpleInfo) {
    try {
      const success = await HistoryUtil.deleteSingle(comic._id);
      if (success) {
        ToastUtil.showToast({ message: `已删除 ${comic.title}` });
      }
    } catch (e) {
      logger.error('删除历史失败');
    }
  }

  /**
   * 取消收藏
   * 注意：这里修改的是传入的数组引用，如果数组是 @Trace 的，外部需注意刷新
   */
  async removeFavourite(comic: ComicSimpleInfo, comics: ComicDetailInfo[]): Promise<boolean> {
    try {
      const res = await favouriteAction(comic._id);
      if (res.action === 'un_favourite') {
        ToastUtil.showToast({ message: `${comic.title} 已取消收藏` });
        return true;
      }
      return false;
    } catch (e) {
      logger.error('取消收藏失败');
      return false;
    }
  }

  /**
   * 统一处理删除/取消收藏操作
   */
  handleDelete(id: string, comic: ComicSimpleInfo, comics: ComicDetailInfo[]) {
    // 开启模糊背景
    PicState.foregroundBlurMode = true
    let deleteTitle = ''
    // 根据类型决定操作逻辑
    if (id === 'reading') {
      deleteTitle = '阅读记录'
    } else if (id === 'history') {
      deleteTitle = '浏览历史'
    } else if (id === 'favourite') {
      deleteTitle = '收藏'
    }
    // 显示确认对话框
    ToastUtil.showDialog({
      title: `是否删除${deleteTitle} ${comic.title}`,
      buttons: [
        { text: '确认', color: $r('app.color.common_button_background_light') },
        { text: '取消', color: $r('app.color.font_color') }
      ]
    }, async (err, data) => {
      if (err) {
        logger.error('Dialog Error: ' + err.message);
        PicState.foregroundBlurMode = false;
        return;
      }
      if (data.index == 0) {
        // 确认操作：调用 ViewModel
        if (id === 'reading') {
          await this.deleteHistory(comic);
          this.readingTick++;   // 通知阅读记录列表重新拉取
          this.markHistoryDirty();  // 同一条记录被删，浏览历史也需刷新
        } else if (id === 'history') {
          await this.deleteHistory(comic);
          this.historyTick++;   // 通知列表重新拉取
          this.markReadingDirty();  // 同一条记录被删，阅读记录也需刷新
        } else if (id === 'favourite') {
          const success = await this.removeFavourite(comic, comics);
          if (success) {
            this.favouriteTick++;  // 直接刷新收藏列表
          }
        }
      }
      // 关闭模糊背景
      PicState.foregroundBlurMode = false
    })
  }

}

export const homeVM: HomeViewModel = new HomeViewModel()
