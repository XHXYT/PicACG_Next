import { ImageKnifeComponent } from '@ohos/imageknife'
import { LogUtil } from '@pura/harmony-utils'
import { SlidingTabsV1 } from '@xqw/sliding-tabs'
import { SlidingTabControllerV1 } from '@xqw/sliding-tabs/src/main/ets/v1/SlidingTabControllerV1'
import { ComicDetailInfo, ComicSimpleInfo, User } from '../../api/models'
import { favouriteAction, myFavourite, profile, punchIn } from '../../api/profile'
import { PreferenceStorageKey } from '../../utils/Preference'
import ComicList from '../component/ComicList'
import CommentList from '../component/CommentList'
import { promptAction } from '@kit.ArkUI'
import { ToastUtil } from '../../utils/ToastUtils'
import { HistoryUtil } from '../../utils/History'
import { EventHub } from '../../utils/EventHub'
import { EventKey } from '../../common/Config'

/**
 * 我的主页
 */
@Component
export default struct Home {

  // 背景模糊
  @StorageLink('foregroundBlur') foregroundBlurMode: boolean = false
  @StorageProp(PreferenceStorageKey.IMAGE_API) imageApi: string = ''
  @State currentIndex: number = 0
  @State animationDuration: number = 300
  @State tabs: string[] = ['浏览历史', '我的收藏', '我的评论']
  @State index: number = 0
  @State AvatarUrl: string = ''
  @State profile: User | undefined = undefined
  swiperController = new SwiperController()
  tabController4 = new SlidingTabControllerV1(this.swiperController)

  aboutToAppear(): void {
    this.loadProfile()
  }

  loadProfile() {
    profile().then(res => {
      this.profile = res.user
      this.AvatarUrl = `${this.imageApi + this.profile?.avatar?.path}`
      LogUtil.info(`Home 是否签到：${JSON.stringify(res.user.isPunched)}`)
      LogUtil.info(`Home 个人信息：${JSON.stringify(res.user)}`)
      LogUtil.info(`Home 头像地址：${this.imageApi + this.profile?.avatar?.path}`)
    })
  }

  build() {
    Column() {
      Column() {
        Row() {
          Column() {
            // 头像
            Image(this.AvatarUrl)
              .width(64)
              .height(64)
              .borderRadius(100)
          }
          .width(64)
          .height(64)
          .margin({ right: 16 })

          Column() {
            // 昵称 + 个签
            Text(`${this.profile?.name}`)
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Start)
              .width('100%')

            Text(`${this.profile?.slogan}`)
              .fontColor(Color.Gray)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Start)
              .width('100%')
          }
          .layoutWeight(1)

          Column() {
            // 签到
            Button('打哔咔')
              .type(ButtonType.Normal)
              .stateEffect(false)
              .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.8 })
              .height(40)
              .width(80)
              .backgroundColor($r('app.color.common_button_background_weight'))
              .borderRadius(8)
              .onClick(() => {
                punchIn()
                  .finally(() => {
                    ToastUtil.showToast({ message: '签到成功', });
                    this.loadProfile()
                  })
              })
          }
          .height(40)
          .width(80)
          .visibility(this.profile?.isPunched ? Visibility.Hidden : Visibility.Visible)
        }
        .height(64)
        .width('100%')

        Row() {
          // 经验条
          Progress({ value: this.profile?.exp, total: 100, type: ProgressType.Capsule })
            .color($r('app.color.common_button_background_weight'))
            .style({
              content: `Lv ${this.profile?.level}`,
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

      SlidingTabsV1({
        index: this.index,
        tabs: this.tabs,
        barMode: 'scroll',
        controller: this.tabController4,
        tabStyle: {
          fontColor: Color.Gray,
          fontColorSelect: $r('app.color.common_button_background_light'),
        },
        indicatorStyle: {
          color: $r('app.color.common_button_background_light'),
          width: 60
        }
      })
      Swiper(this.tabController4.swiperController) {
        // 浏览记录
        Stack() {
          ComicList({
            attr: { type: 'history' },
            deleteOperate: (comic, comics) => {
              this.deleteOperate('history', comic, comics)
            }
          })
        }
        .width('100%').height('100%')
        // 收藏
        Stack() {
          ComicList({
            attr: { type: 'remote', api: myFavourite },
            deleteOperate: (comic, comics) => {
              this.deleteOperate('favourite', comic, comics)
            }
          })
        }
        .width('100%').height('100%')
        // 我的评论
        Stack() {
          CommentList({ avatar: `${this.profile?.avatar?.path}` })
        }
        .width('100%').height('100%')
      }
      .padding({ left: 10, right: 10, top: 5 })
      .indicator(false)
      .layoutWeight(1)
      .onGestureSwipe((index, extraInfo) => {
        this.tabController4.swiperOnGestureSwipe(index, extraInfo)
      })
      .onAreaChange((oldValue, newValue) => {
        this.tabController4.swiperOnAreaChange(oldValue, newValue)
      })
      .onAnimationStart((index, targetIndex, extraInfo) => {
        this.tabController4.swiperOnAnimationStart(index, targetIndex, extraInfo)
      })
    }.backgroundColor($r('app.color.start_window_background'))
    .height('100%')
    .width('100%')
  }

  // 删除操作
  deleteOperate(id: string, comic: ComicSimpleInfo, comics: ComicDetailInfo[]) {
    this.foregroundBlurMode = true
    let deleteTitle = ''
    let deleteOp: () => void = () => {}
    switch (id) {
      case 'history':
        deleteTitle = '浏览历史'
        deleteOp = () => {
          this.deleteHistory(comic)
        }
        break
      case 'favourite':
        deleteTitle = '收藏'
        deleteOp = () => {
          this.operateFavourite(comic, comics)
        }
        break
    }
    ToastUtil.showDialog({
      title: `是否删除${deleteTitle} ${comic.title}`,
      buttons: [
        { text: '确认', color: $r('app.color.common_button_background_light') },
        { text: '取消', color: $r('app.color.font_color') }
      ]
    }, (err, data) => {
      if (err) {
        console.error('Pica #deleteOperate showDialog err.code: ' + err.code + ', err.message: ' + err.message);
        return;
      }
      if (data.index == 0) {
        // 确认删除
        deleteOp()
        console.error(`#deleteOperate 确认删除`)
      } else {
        console.log(`#deleteOperate 取消删除`)
      }
      this.foregroundBlurMode = false
    })
  }

  // 删除浏览记录
  deleteHistory(comic: ComicSimpleInfo) {
    HistoryUtil.deleteSingle(comic._id).then((value) => {
      if (value) {
        EventHub.sendEvent<EventKey>(EventKey.LoadHistory, comic._id)
        ToastUtil.showToast({ message: `已删除 ${comic.title}`});
      }
    })
  }

  // 收藏操作
  operateFavourite(comic: ComicSimpleInfo, comics: ComicDetailInfo[]) {
    favouriteAction(comic._id)
      .then(res => {
        if (res.action === 'un_favourite') {
          ToastUtil.animateTo({ duration: 500 }, () => {
            comics = comics.filter(c => c._id !== comic._id)
          })
          ToastUtil.showToast({ message: `${comic.title} 已取消收藏`});
        }
      })
  }

}