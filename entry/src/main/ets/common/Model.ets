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