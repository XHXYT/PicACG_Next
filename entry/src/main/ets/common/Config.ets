import { SortType } from '../api/models'
import { SearchType } from '../pages/view/Comics'
import { PreferenceItem } from '../utils/Preference'

const Host = 'picaapi.picacomic.com'
const NewChatUrl = 'https://live-server.bidobido.xyz/'
const SecretKey = '~d}$Q7$eIni=V)9\\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn'
const ApiKey = 'C69BAF41DA5ABD1FFEDC6D2FEA56B'
const AppNonce = '1b509109-476d-3790-a5f0-0acfeace9a5b'
const AppUuid = 'webUUID'
const AppVersion = '2.2.1.3.3.4'
const BuildVersion = '45'
const Accept = 'application/vnd.picacomic.com.v1+json'
const Agent = 'okhttp/3.8.1'
const Platform = 'android'

enum Api {
  Origin = 'https://picaapi.picacomic.com/',
  Proxy = 'https://api.go2778.com/',
}

enum ImageApi {
  TriageOne = 'https://s3.picacomic.com/static/',
  TriageTwo = 'https://s2.picacomic.com/static/',
  TriageThree = 'https://storage1.picacomic.com/static/',
  ProxyOne = 'https://pica.luxcis.xyz/static/',
  ProxyTwo = 'https://storage.diwodiwo.xyz/static/',
}

enum ImageQuality {
  Original = 'original',
  High = 'high',
  Medium = 'medium',
  Low = 'low',
}

enum AppChannel {
  One = '1',
  Two = '2',
  Three = '3'
}

interface LocalCategory {
  title: string
  img: ResourceStr
  router: string
  param?: ESObject
}

const LocalCategories: LocalCategory[] = [
  {
    title: '排行榜',
    img: $r('app.media.cat_leaderboard'),
    router: 'Leaderboard'
  },
  {
    title: '哔咔留言板',
    img: $r('app.media.cat_forum'),
    router: 'Comments'
  },
  {
    title: '最近更新',
    img: $r('app.media.cat_latest'),
    router: 'Comics',
    param: { type: SearchType.Category, title: '最近更新' }
  },
  {
    title: '随机本子',
    img: $r('app.media.cat_random'),
    router: 'Comics',
    param: { type: SearchType.Random, title: '随机本子' }
  }
]

const CategoryFilter: string[] = ['援助嗶咔', '嗶咔小禮物', '小電影', '小里番', '嗶咔畫廊', '嗶咔商店', '嗶咔運動']

const SortItems: PreferenceItem[] = [
  {
    name: '从新到旧',
    value: SortType.Newest,
    key: 'Newest',
    icon: $r('sys.symbol.text_and_arrow_down')
  },
  {
    name: '从旧到新',
    value: SortType.Oldest,
    key: 'Oldest',
    icon: $r('sys.symbol.text_and_arrow_up')
  },
  {
    name: '最多爱心',
    value: SortType.Likest,
    key: 'Likest',
    icon: $r('sys.symbol.heart')
  },
  {
    name: '最多收藏',
    value: SortType.Favorite,
    key: 'Favorite',
    icon: $r('sys.symbol.eye')
  },
]

export {
  Host,
  NewChatUrl,
  SecretKey,
  ApiKey,
  AppChannel,
  AppNonce,
  AppUuid,
  AppVersion,
  BuildVersion,
  Accept,
  Agent,
  Platform,
  Api,
  ImageApi,
  ImageQuality,
  LocalCategories,
  CategoryFilter,
  LocalCategory,
  SortItems
}