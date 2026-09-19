import { SlidingTabsV2 } from '@xqw/sliding-tabs'
import { SlidingTabControllerV2 } from '@xqw/sliding-tabs/src/main/ets/v2/SlidingTabControllerV2'
import { ComicDetailInfo, ComicSimpleInfo } from '../api/models'
import { myFavourite } from '../api/profile'
import ComicList from './component/ComicList'
import CommentList from './component/CommentList'
import { HomeViewModel, homeVM } from '../viewmodel/HomeViewModel'
import { PicState } from '../entryability/AppState'
import { UserAvatar } from './component/UserAvatar'
import { AccountManage } from './view/AccountManage'


@ComponentV2
export default struct Home {

  @Local viewModel: HomeViewModel = homeVM
  // 账号管理半模态
  @Local isShowAccountManage: boolean = false

  // 控制器
  swiperController: SwiperController = new SwiperController()
  tabController: SlidingTabControllerV2 = new SlidingTabControllerV2()
  // 常量数据
  tabs: string[] = ['阅读记录', '浏览历史', '我的收藏', '我的评论']

  aboutToAppear(): void {
    this.viewModel.loadProfile()
  }

  build() {
    Column() {
      // 顶部用户信息区
      Column() {
        Row() {
          // 头像
          UserAvatar({
            avatarUrl: this.viewModel.avatarUrl,
            displayName: this.viewModel.user?.name ?? '',
            avatarSize: 64
          })
            .margin({ right: 16 })

          // 昵称 + 个签
          Column() {
            Text(`${this.viewModel.user?.name}`)
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Start)
              .width('100%')

            Text(`${this.viewModel.user?.slogan}`)
              .fontColor(Color.Gray)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Start)
              .width('100%')
          }
          .layoutWeight(1)

          // 签到按钮
          Column() {
            Button('打哔咔')
              .type(ButtonType.Normal)
              .stateEffect(false)
              .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.8 })
              .height(40)
              .width(80)
              .backgroundColor($r('app.color.common_button_background_weight'))
              .borderRadius(8)
              .onClick(() => {
                this.viewModel.doPunchIn()
              })
          }
          .height(40)
          .width(80)
          // 根据 ViewModel 状态控制显隐
          .visibility(this.viewModel.isPunched ? Visibility.Hidden : Visibility.Visible)
        }
        .height(64)
        .width('100%')
        // 长按用户信息区弹出账号管理半模态
        .gesture(LongPressGesture({ repeat: false })
          .onAction(() => {
            this.isShowAccountManage = true
          }))
        .bindSheet(this.isShowAccountManage!!, this.accountManageSheet(), {
          detents: [650, SheetSize.LARGE],
          dragBar: false,
          backgroundColor: $r('app.color.start_window_background'),
          onWillAppear: () => {
            PicState.foregroundBlurMode = true
          },
          onWillDisappear: () => {
            PicState.foregroundBlurMode = false
          }
        })

        Row() {
          // 经验条
          Progress({
            value: this.viewModel.user?.exp,
            total: 100,
            type: ProgressType.Capsule
          })
            .color($r('app.color.common_button_background_weight'))
            .style({
              content: `Lv ${this.viewModel.user?.level}`,
              font: { size: 12, style: FontStyle.Normal },
              borderWidth: 0
            })
            .backgroundColor($r('app.color.custom_gray'))
            .height(14)
        }
        .height(36)
        .width('100%')
      }
      .width('100%')
      .height(100)
      .padding({ left: 16, right: 16, top: 16 })

      // Tab 栏
      SlidingTabsV2({
        tabs: this.tabs,
        barMode: 'scroll',
        tabController: this.tabController,
        onChange: (index: number) => {
          this.viewModel.currentSubIndex = index
          // 子 Tab 切换时消费该列表的脏标记
          this.viewModel.consumeDirtyAt(index)
          this.swiperController.changeIndex(index)
        },
        tabStyle: {
          fontColor: Color.Gray,
          fontColorSelect: $r('app.color.common_button_background_light'),
        },
        indicatorStyle: {
          color: $r('app.color.common_button_background_light'),
          width: 60
        }
      })

      // 内容区
      Swiper(this.swiperController) {
        // 阅读记录
        Stack() {
          ComicList({
            attr: { type: 'reading' },
            refreshTick: this.viewModel.readingTick,
            deleteOperate: (comic: ComicSimpleInfo, comics: ComicDetailInfo[]) => {
              this.viewModel.handleDelete('reading', comic, comics)
            },
            onItemClick: (comic) => {
              PicState.pageStack.pushPathByName('comic_detail', comic)
            }
          })
        }
        .width('100%')
        .height('100%')

        // 浏览记录
        Stack() {
          ComicList({
            attr: { type: 'history' },
            refreshTick: this.viewModel.historyTick,
            deleteOperate: (comic: ComicSimpleInfo, comics: ComicDetailInfo[]) => {
              this.viewModel.handleDelete('history', comic, comics)
            },
            onItemClick: (comic) => {
              PicState.pageStack.pushPathByName('comic_detail', comic)
            }
          })
        }
        .width('100%')
        .height('100%')

        // 我的收藏
        Stack() {
          ComicList({
            attr: { type: 'remote', api: myFavourite },
            refreshTick: this.viewModel.favouriteTick,
            deleteOperate: (comic: ComicSimpleInfo, comics: ComicDetailInfo[]) => {
              this.viewModel.handleDelete('favourite', comic, comics)
            },
            onItemClick: (comic) => {
              PicState.pageStack.pushPathByName('comic_detail', comic)
            }
          })
        }
        .width('100%')
        .height('100%')

        // 我的评论
        Stack() {
          CommentList({
            // 传入头像路径，未登录时为空字符串
            avatar: this.viewModel.avatarUrl,
            refreshTick: this.viewModel.commentTick,
            onComicClick: (comic) => {
              PicState.pageStack.pushPathByName('comic_detail', comic)
            }
          })
        }
        .width('100%')
        .height('100%')
      }
      .padding({ left: 10, right: 10, top: 5 })
      .indicator(false)
      .layoutWeight(1)
      .onGestureSwipe((index, extraInfo) => {
        this.tabController.swiperOnGestureSwipe(index, extraInfo)
      })
      .onAreaChange((oldValue, newValue) => {
        this.tabController.swiperOnAreaChange(oldValue, newValue)
      })
      .onAnimationStart((index, targetIndex, extraInfo) => {
        this.tabController.swiperOnAnimationStart(index, targetIndex, extraInfo)
      })
    }
    .backgroundColor($r('app.color.start_window_background'))
    .height('100%')
    .width('100%')
  }

  /**
   * 账号管理半模态内容：
   */
  @Builder
  accountManageSheet() {
    AccountManage({ isMainPage: true })
  }

}
