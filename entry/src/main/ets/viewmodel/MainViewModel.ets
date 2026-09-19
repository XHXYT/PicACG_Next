import { collections, leaderboard, otherRecommend, random, ComicResponse } from '../api/comic';
import { LogUtil } from '@pura/harmony-utils';
import { PreferenceManager } from '../utils/preference/Settings';
import { ReplaceImageApi } from '../common/Consts';
import { TimeType } from '../api/models';
import { ComicCardInterface } from '../common/Model';


@ObservedV2
export class MainViewModel {
  @Trace random: ComicCardInterface[] = [];
  @Trace recommend: ComicCardInterface[] = [];
  @Trace collections: ComicCardInterface[] = [];

  // 刷新信号：递增触发轮播图重新加载（下拉刷新/双击首页Tab共用）
  @Trace refreshTick: number = 0;

  /**
   * 外部请求刷新（双击首页Tab触发）
   */
  requestRefresh(): void {
    this.refreshTick++;
  }

  /**
   * 初始化数据加载
   */
  async init() {
    // 并行请求，提升加载速度
    await Promise.all([
      this.loadRecommend(),
      this.loadRandom(),
      this.loadCollection()
    ]);
  }

  /**
   * 排行榜数据加载 (适配 ComicBanner 组件接口)
   */
  async fetchLeaderboard(): Promise<ComicResponse> {
    try {
      const res = await leaderboard(TimeType.Hour24);
      // 构造符合 ComicResponse 接口的对象
      const response: ComicResponse = {
        comics: {
          docs: res.comics,
          page: 1,
          pages: 1,
          total: res.comics.length,
          limit: res.comics.length
        }
      };
      return response;
    } catch (err) {
      LogUtil.error(`排行榜加载错误: ${JSON.stringify(err)}`);
      // 抛出错误或返回空数据结构，防止 UI 崩溃
      const emptyResponse: ComicResponse = {
        comics: { docs: [], page: 1, pages: 0, total: 0, limit: 0 }
      };
      return emptyResponse;
    }
  }

  /**
   * 加载随机推荐
   */
  private async loadRecommend() {
    try {
      const res = await otherRecommend();
      // 显式定义数组类型
      const list: ComicCardInterface[] = res.map((comic): ComicCardInterface => {
        return {
          id: comic.id,
          title: comic.title,
          image: ReplaceImageApi(comic.pic)
        };
      });
      this.recommend = list;
      LogUtil.info(`随机推荐: ${res.length}`);
    } catch (err) {
      LogUtil.error(`随机推荐加载错误: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 加载随机本子
   */
  private async loadRandom() {
    try {
      const res = await random();
      // 显式定义数组类型
      const list: ComicCardInterface[] = res.comics.map((comic): ComicCardInterface => {
        return {
          id: comic._id,
          title: `${comic.title}（${comic.pagesCount}P）${comic.finished ? '（完）' : ''}`,
          image: `${PreferenceManager.image_api}${comic.thumb.path}`
        };
      });
      this.random = list;
    } catch (err) {
      LogUtil.error(`随机本子加载错误: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 加载本子妹推荐
   */
  private async loadCollection() {
    try {
      const res = await collections();
      const tempList: ComicCardInterface[] = [];

      res.collections.forEach(collection => {
        collection.comics.forEach(comic => {
          // 构造符合接口的对象
          const item: ComicCardInterface = {
            id: comic._id,
            title: `${comic.title}（${comic.pagesCount}P）${comic.finished ? '（完）' : ''}`,
            image: `${PreferenceManager.image_api}${comic.thumb.path}`
          };
          tempList.push(item);
        });
      });

      this.collections = tempList;
    } catch (err) {
      LogUtil.error(`本子妹推荐加载错误: ${JSON.stringify(err)}`);
    }
  }

}

export const mainVM: MainViewModel = new MainViewModel()
