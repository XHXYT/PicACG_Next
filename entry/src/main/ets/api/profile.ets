import { HttpUtil } from '../utils/Http'
import { PicaPage } from '../common/Model'
import { Comment, PunchIn, SortType, User } from './models'
import { ComicResponse } from './comic'

export interface ProfileResponse {
  user: User
}

export interface CommentResponse {
  comments: PicaPage<Comment>
  topComments: Comment[] // 格式存疑待验证
}

export interface ComicActionResponse {
  action: 'favourite' | 'un_favourite' | 'like' | 'unlike'
}

export interface PunchInResponse {
  res: PunchIn
}

/**个人信息*/
export const profile = (): Promise<ProfileResponse> => {
  return HttpUtil.get('/users/profile')
}

/**我的最爱*/
export const myFavourite = (page: number = 1, s: SortType = SortType.Newest): Promise<ComicResponse> => {
  return HttpUtil.get('/users/favourite', { page, s })
}

/**收藏操作，未收藏漫画调用后进入收藏，已收藏漫画调用后删除收藏*/
export const favouriteAction = (id: string): Promise<ComicActionResponse> => {
  return HttpUtil.post(`/comics/${id}/favourite`)
}

export const likeAction = (id: string): Promise<ComicActionResponse> => {
  return HttpUtil.post(`/comics/${id}/like`)
}

/**我的评论*/
export const myComments = (page: number = 1): Promise<CommentResponse> => {
  return HttpUtil.get('/users/my-comments', { page })
}

/**打哔咔*/
export const punchIn = (): Promise<PunchInResponse> => {
  return HttpUtil.post('/users/punch-in')
}