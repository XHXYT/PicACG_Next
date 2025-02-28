export class NavItem {
  /**
   * tab图标
   */
  tabIcons: Resource
  /**
   * 标题
   */
  title: string
  /**
   * Index
   */
  index: number
  builder: CustomBuilder

  constructor(index: number, tabIcons: Resource, title: string, builder: CustomBuilder) {
    this.tabIcons = tabIcons
    this.title = title
    this.index = index
    this.builder = builder
  }
}