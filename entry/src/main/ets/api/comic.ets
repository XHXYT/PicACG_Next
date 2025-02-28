import axios, { AxiosResponse } from '@ohos/axios'
import { MD5, RandomUtil } from '@pura/harmony-utils'
import { HttpUtil } from '../utils/Http'
import { PicaPage } from '../common/Model'
import { Category, Chapter, ComicDetailInfo, ComicEp, ComicSimpleInfo, SortType, TimeType, User } from './models'
import { ComicActionResponse, CommentResponse } from './profile'

export interface CollectionResponse {
  collections: Collection[]
}

export interface Collection {
  title: string
  comics: ComicSimpleInfo[]
}

export interface CommonComicsResponse {
  comics: ComicDetailInfo[]
}

export interface DetailResponse {
  comic: ComicDetailInfo
}

export interface Recommend {
  id: string
  pic: string
  title: string
}

export interface CategoryResponse {
  categories: Category[]
}

export interface ComicResponse {
  comics: PicaPage<ComicDetailInfo>
}

export interface EpsResponse {
  eps: PicaPage<ComicEp>
}

export interface RandomResponse {
  comics: ComicDetailInfo[]
}

export interface KeywordResponse {
  keywords: string[]
}

export interface ChapterResponse {
  ep: ComicEp,
  pages: PicaPage<Chapter>
}

export interface UserResponse {
  users: User[]
}

/**另一个推荐接口: 其他人还在看(不需要认证)*/
export const otherRecommend = (_id?: string) => {
  if (!_id) {
    _id = MD5.digestSync(RandomUtil.getRandomNumber(Number.MIN_VALUE, Number.MAX_VALUE).toString()).substring(0, 24)
  }
  return new Promise<Recommend[]>((resolve, reject) => {
    axios.get('https://recommend.go2778.com/pic/recommend/get/?c=' + _id)
      .then((res: AxiosResponse<Recommend[]>) => {
        resolve(res.data)
      })
      .catch((err: Error) => {
        reject(err)
      })
  })
}

/**本子妹推荐*/
export const collections = (): Promise<CollectionResponse> => {
  return HttpUtil.get('/collections')
}

/**相关推荐*/
export const recommendation = (comicId: string): Promise<CommonComicsResponse> => {
  return HttpUtil.get(`/comics/${comicId}/recommendation`)
}

/**漫画详细信息*/
export const detail = (comicId?: string): Promise<DetailResponse> => {
  return HttpUtil.get(`/comics/${comicId}`)
}

/**漫画目录*/
export const eps = (comicId: string, page: number = 1): Promise<EpsResponse> => {
  return HttpUtil.get(`/comics/${comicId}/eps`, { page })
}

/**分类*/
export const categories = (): Promise<CategoryResponse> => {
  return HttpUtil.get('categories')
}

/**根据分类查询漫画分页*/
export const comicsByCategory =
  (page: number = 1, s: SortType = SortType.Newest, c: string): Promise<ComicResponse> => {
    return HttpUtil.get('/comics', { page, s, c: encodeURI(c) })
  }

/**根据上传者查询漫画分页*/
export const comicsByUploader =
  (page: number = 1, s: SortType = SortType.Newest, ca: string): Promise<ComicResponse> => {
    return HttpUtil.get('/comics', { page, s, ca })
  }

/**根据作者查询漫画分页*/
export const comicsByAuthor =
  (page: number = 1, s: SortType = SortType.Newest, a: string): Promise<ComicResponse> => {
    return HttpUtil.get('/comics', { page, s, a: encodeURI(a) })
  }

/**根据汉化组查询漫画分页*/
export const comicsByTeam =
  (page: number = 1, s: SortType = SortType.Newest, ct: string): Promise<ComicResponse> => {
    return HttpUtil.get('/comics', { page, s, ct: encodeURI(ct) })
  }

/**关键字查询分页列表*/
export const search = (page: number = 1, s: SortType = SortType.Newest, keyword?: string, categories?: string[]):
  Promise<ComicResponse> => {
  return HttpUtil.request('POST', '/comics/advanced-search', {
    params: { page, s },
    data: {
      categories,
      keyword,
      sort: s
    }
  })
}

/**随机本子*/
export const random = (): Promise<RandomResponse> => {
  return HttpUtil.get('/comics/random')
}

/**大家都在搜*/
export const keywords = (): Promise<KeywordResponse> => {
  return HttpUtil.get('/keywords')
}

/**漫画评论*/
export const comments = (page: number = 1, comicId: string): Promise<CommentResponse> => {
  return HttpUtil.get(`/comics/${comicId}/comments`, { page })
}

/**回复评论*/
export const sendComment = (comicId: string, content: string): Promise<void> => {
  return HttpUtil.post(`/comics/${comicId}/comments`, { content })
}

/**评论点赞*/
export const likeComment = (commentId: string): Promise<ComicActionResponse> => {
  return HttpUtil.post(`/comments/${commentId}/like`)
}

/**评论楼中楼*/
export const commentsChildren = (page: number = 1, commentId: string): Promise<CommentResponse> => {
  return HttpUtil.get(`/comments/${commentId}/childrens`, { page })
}

/**回复评论*/
export const replyComment = (commentId: string, content: string): Promise<void> => {
  return HttpUtil.post(`/comments/${commentId}`, { content })
}

/**漫画章节内容*/
export const chapter = (comicId: string, order: number = 1, page: number = 1): Promise<ChapterResponse> => {
  return HttpUtil.get(`/comics/${comicId}/order/${order}/pages`, { page })
}

/**排行榜*/
export const leaderboard = (tt: TimeType, ct: string = 'VC'): Promise<CommonComicsResponse> => {
  return HttpUtil.get('/comics/leaderboard', { tt, ct })
}

/**骑士排行榜*/
export const knightLeaderboard = (): Promise<UserResponse> => {
  return HttpUtil.get('/comics/knight-leaderboard')
}
