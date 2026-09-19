import { detail, eps, recommendation } from '../api/comic'
import { ComicDetailInfo, ComicEp } from '../api/models'
import { favouriteAction, likeAction } from '../api/profile'
import { ComicCardInterface, ComicListOptions, SearchType } from '../common/Model'
import { PicState } from '../entryability/AppState'
import { HistoryUtil } from '../utils/History'
import { createLogger } from '../utils/Logger'
import { PreferenceManager } from '../utils/preference/Settings'
import { ToastUtil } from '../utils/ToastUtils'
import { homeVM } from './HomeViewModel'

const logger = createLogger('ComicDetailVM')


@ObservedV2
export class ComicDetailVM {
  @Trace comic: ComicCardInterface | undefined = undefined
  @Trace detail: ComicDetailInfo = emptyComicDetailInfo
  @Trace eps: ComicEp[] = []
  @Trace recommend: ComicCardInterface[] = []
  @Trace showComments: boolean = false
  @Trace currentOrder: number = 0

  private pageInfos: NavPathStack | null = null

  // 初始化方法
  async init(navStack: NavPathStack, param: ComicCardInterface) {
    this.pageInfos = navStack
    this.comic = param
    logger.info(`'init 本子详情页：', ${this.comic.id}, ${this.comic.title}`)

    try {
      // 远程查询
      const res = await detail(this.comic.id)
      this.detail = res.comic
      this.detail.lastReadOrder = 1

      // 保存历史记录
      await HistoryUtil.add(this.detail)
      homeVM.markHistoryDirty()
      // 加载章节
      this.loadEps(this.comic.id, 1)

      // 加载推荐
      this.loadRecommendations(this.comic.id)

      // 本地浏览记录
      const hres = await HistoryUtil.getComicDetail(this.comic.id)
      if (hres) {
        this.updateReadHistory(hres)
      }
    } catch (e) {
      logger.error('ComicDetail init failed:', e)
    }
  }

  // 页面显示时的逻辑
  async onPageShown() {
    if (!this.detail._id) return
    const res = await HistoryUtil.getComicDetail(this.detail._id)
    if (res) {
      this.updateReadHistory(res)
    }
  }

  // 更新阅读历史
  private updateReadHistory(hres: ComicDetailInfo) {
    this.currentOrder = hres.lastReadOrder
    // 仅同步阅读进度（章节+页码），保留当前实时的收藏/喜欢状态（本地快照可能是旧值）
    this.replaceDetail(this.detail.isFavourite, this.detail.isLiked, this.detail.likesCount,
      hres.lastReadOrder, hres.lastReadIndex)
    console.log(`ComicDetail 更新 ${this.detail.title}，阅读记录至${hres.lastReadOrder}章 第${hres.lastReadIndex}页`)
  }

  // 整体重新赋值 detail 以触发 @Trace 状态更新（interface 对象的字段修改不会被观测）
  private replaceDetail(isFavourite: boolean, isLiked: boolean, likesCount: number,
    lastReadOrder: number, lastReadIndex: number): void {
    const d = this.detail
    this.detail = {
      _id: d._id,
      title: d.title,
      thumb: d.thumb,
      author: d.author,
      categories: d.categories,
      finished: d.finished,
      epsCount: d.epsCount,
      pagesCount: d.pagesCount,
      totalViews: d.totalViews,
      totalLikes: d.totalLikes,
      _creator: d._creator,
      description: d.description,
      chineseTeam: d.chineseTeam,
      tags: d.tags,
      updated_at: d.updated_at,
      created_at: d.created_at,
      allowDownload: d.allowDownload,
      allowComment: d.allowComment,
      totalComments: d.totalComments,
      viewsCount: d.viewsCount,
      likesCount: likesCount,
      commentsCount: d.commentsCount,
      isFavourite: isFavourite,
      isLiked: isLiked,
      lastReadOrder: lastReadOrder,
      lastReadIndex: lastReadIndex,
    }
  }

  // 递归加载章节
  private loadEps(id: string, page: number) {
    eps(id, page).then(res => {
      // 这里使用数组 push 后需要触发状态更新，V2版本@Trace数组push默认监听
      this.eps.push(...res.eps.docs)
      if (page < res.eps.pages) {
        this.loadEps(id, page + 1)
      }
    })
  }

  // 加载推荐
  private loadRecommendations(id: string) {
    recommendation(id).then(res => {
      res.comics.forEach((comic) => {
        this.recommend.push({
          id: comic._id,
          title: `${comic.title}（${comic.pagesCount}P）${comic.finished ? '（完）' : ''}`,
          image: `${PreferenceManager.image_api}${comic.thumb.path}`
        })
      })
    })
  }

  // 跳转漫画详情
  goDetail(comic: ComicCardInterface) {
    this.pageInfos?.pushPathByName('comic_detail', comic)
  }

  // 跳转阅读器
  goToReader(chapter: number) {
    if (this.detail) {
      const targetOrder = chapter > 0 ? chapter : 1
      // 页码进度只属于上次的章节：主动切换章节时从该章第一页开始
      this.detail.lastReadIndex = targetOrder === this.detail.lastReadOrder ? this.detail.lastReadIndex : 0
      this.detail.lastReadOrder = targetOrder
      console.log(`前往阅读 ${this.detail.title} 第${targetOrder}章 第${this.detail.lastReadIndex}页`)
      this.pageInfos?.pushPathByName('comic_reader', this.detail)
    }
  }

  // 收藏操作
  toggleFavourite() {
    this.replaceDetail(!this.detail.isFavourite, this.detail.isLiked, this.detail.likesCount,
      this.detail.lastReadOrder, this.detail.lastReadIndex)
    favouriteAction(this.detail._id).then(res => {
      ToastUtil.showToast({ message: res.action === 'favourite' ? '收藏成功' : '取消收藏成功' })
      homeVM.markFavouriteDirty()
    })
    logger.info('点击收藏')
  }

  // 喜欢操作
  toggleLike() {
    this.replaceDetail(this.detail.isFavourite, !this.detail.isLiked,
      this.detail.isLiked ? this.detail.likesCount - 1 : this.detail.likesCount + 1,
      this.detail.lastReadOrder, this.detail.lastReadIndex)
    likeAction(this.detail._id).then(res => {
      ToastUtil.showToast({ message: res.action === 'like' ? '喜欢成功' : '取消喜欢成功' })
    })
    logger.info('点击喜欢')
  }

  // 评论点击
  toggleComments(show: boolean) {
    this.showComments = show
    PicState.foregroundBlurMode = show
  }

  // 标签点击跳转
  goSearch(type: SearchType, key: string, title?: string) {
    const options: ComicListOptions = { type, key, title }
    this.pageInfos?.pushPathByName('comics', options)
  }
}

// 空对象定义需保留或引入
export const emptyComicDetailInfo: ComicDetailInfo = {
  _id: '', title: '', thumb: { originalName: undefined, path: '', fileServer: '' },
  author: '', categories: [], finished: false, epsCount: 0, pagesCount: 0,
  totalViews: 0, totalLikes: 0, _creator: { _id: '', gender: '', name: '', title: '', slogan: '', verified: false, exp: 0, level: 0, characters: [], role: '', avatar: undefined },
  description: '', chineseTeam: '', tags: [], updated_at: '', created_at: '',
  allowDownload: false, allowComment: false, totalComments: 0,
  viewsCount: 0, likesCount: 0, commentsCount: 0, isFavourite: false, isLiked: false,
  lastReadOrder: 1, lastReadIndex: 0,
}
