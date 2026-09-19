import { ComicResponse } from "../api/comic"
import { SortType } from "../api/models"

export interface PicaResponse<T> {
  code: number
  message: string
  error?: string
  detail?: string
  data?: T
}


export interface PicaPage<T> {
  docs: T[]
  page: number
  pages: number
  total: number
  limit: number
}

export interface SettingsItemAttribute {
  image?: Resource
  name: string,
  subtitle?: string
  menus?: PreferenceItem[]
  tips?: string,
  type?: 'Normal' | 'Switch' | 'Tips' | 'Menu'
  /** Switch 形态：true 时点击整行即可启闭开关 */
  switchByRow?: boolean
  onClick?: () => void
  menuValue?: string
  switchVal?: boolean
  onValueChange?: (value: number | string) => void
  onChange?: (isOn: boolean) => void
}


export interface PreferenceItem {
  name: string
  value: string,
  key: string,
  icon?: ResourceStr
}


export interface ComicCardInterface {
  id: string
  image: string
  title: string
}

export interface ComicListAttribute {
  type: 'history' | 'reading' | 'remote',
  api?: (page?: number, s?: SortType, p3?: string, p4?: string | string[]) => Promise<ComicResponse>
  sort?: SortType
  param1?: string
  param2?: string | string[]
}


export interface ComicListOptions {
  type: SearchType
  title?: string
  key?: string
}

export enum SearchType {
  Random,
  Category,
  Custom,
  Uploader,
  Author,
  Team
}

