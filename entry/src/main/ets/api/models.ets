export interface ComicSimpleInfo {
  _id: string // id
  title: string // 标题
  thumb: Thumb //封面信息
  author: string // 作者
  categories: string[] // 分类
  finished: boolean // 是否完结
  epsCount: number // 章节的页码，一般为1（要超过40章才有翻页）
  pagesCount: number // 总页数
  totalViews: number // 观看人数
  totalLikes: number // 喜欢人数
}

export interface ComicDetailInfo extends ComicSimpleInfo {
  _creator: Creator // 上传者
  description: string
  chineseTeam: string
  tags: string[]
  updated_at: string
  created_at: string
  allowDownload: boolean // 是否允许下载
  allowComment: boolean // 是否允许评论
  totalComments: number // 评论总数
  viewsCount: number
  likesCount: number
  commentsCount: number
  isFavourite: boolean // 是否收藏
  isLiked: boolean // 是否喜欢
  lastReadOrder: number
  lastReadIndex: number
}

export interface ComicEp {
  _id: string
  id: string
  title: string
  order: number
  updated_at: string
}

export interface Thumb {
  originalName?: string // 文件名
  path: ResourceStr // 文件路径
  fileServer: string // 文件服务
}

export interface Creator {
  _id: string
  gender: string
  name: string //用户名称
  title: string // 头衔
  slogan: string // 个性签名
  verified: boolean
  exp: number
  level: number
  characters: string[]
  role: string
  avatar?: Thumb
}

export interface User extends Creator {
  birthday: string
  email: string
  gender: string
  created_at: string
  isPunched: boolean
  character: string
  comicsUploaded: number
}

export interface Comment {
  id: string
  content: string
  hide: boolean
  created_at: string
  totalComments: number
  likesCount: number
  commentsCount: number
  isLiked: boolean
  isTop: boolean
  _id: string
  _comic: ComicSimpleInfo
  _user: Creator
}

export interface Category {
  _id: string
  title: string
  description?: string
  thumb: Thumb
  link?: string
  isWeb?: boolean
  active?: boolean
}

export interface PunchIn {
  punchInLastDay: string
  status: string
}

export interface Chapter {
  id: string
  _id: string
  media: Thumb
}

export enum SortType {
  Newest = 'dd',
  Oldest = 'da',
  Likest = 'ld',
  Favorite = 'vd'
}

export enum TimeType {
  Day30 = 'D30',
  Day7 = 'D7',
  Hour24 = 'H24',
}
