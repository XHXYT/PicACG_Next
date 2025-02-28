import { router } from '@kit.ArkUI';
import { LogUtil } from '@pura/harmony-utils';

/**
 * 视图类型
 */
export enum TitleType {
  NONE = 'none', // 空白
  TEXT = 'text', // 文字
  IMAGE = 'image', // 图标
  CUSTOM = 'custom', // 自定义
  SEARCH = 'search', // 居中搜索框
}

/**
 * 返回方式
 * MainPage为其他使用TitleBar子组件的组件
 * 如果使用以下方式，自定义左侧图图标点击事件（onClickLeftImage）即可
 */
export enum BackType {
  NONE = 'none', // 无点击事件
  ROUTER = 'router', // router.back() 返回到上一页
}

export enum TitleGlobalAttribute {
  STATUS_BAR_HEIGHT = 'statusBarHeight', // 状态栏高度
  IS_FULL_SCREEN = 'isFullScreen', // 是否是全面屏,全面屏的标题栏高度会加上状态栏高度
  TITLE_BAR_HEIGHT = 'titleBarHeight', // 标题栏高度
  TITLE_BAR_COLOR = 'titleBarColor', // 标题栏颜色
  STATUS_BAR_COLOR = 'statusBarColor', // 状态栏颜色 默认 等于标题栏颜色
  SHOW_BOTTOM_LINE = 'showBottomLine', // 否显示标题栏底部的分割线
  BOTTOM_LINE_SIZE = 'bottomLineSize', // 标题栏底部的分割线的宽度
  BOTTOM_LINE_COLOR = 'bottomLineColor', // 标题栏分割线颜色
  LEFT_LEFT_PADDING = 'leftLeftPadding', // 左侧视图左内间距
  LEFT_RIGHT_PADDING = 'leftRightPadding', // 左侧视图右内间距
  LEFT_TEXT_COLOR = 'leftTextColor', // 左侧文字颜色
  LEFT_TEXT_SIZE = 'leftTextSize', // 左侧文字大小
  LEFT_TYPE = 'leftType', // 左侧视图类型
  LEFT_IMAGE_RESOURCE = 'leftImageResource', // 左侧图标
  LEFT_IMAGE_WIDTH = 'leftImageWidth', // 全局设置左侧图标宽度
  LEFT_IMAGE_HEIGHT = 'leftImageHeight', // 全局设置左侧图标高度
  LEFT_IMAGE_PADDING = 'leftImagePadding', // 全局设置左侧图标padding

  RIGHT_LEFT_PADDING = 'rightLeftPadding', // 右侧视图左内间距
  RIGHT_RIGHT_PADDING = 'rightRightPadding', // 右侧视图右内间距
  RIGHT_TEXT_COLOR = 'rightTextColor', // 右侧文字颜色
  RIGHT_TEXT_SIZE = 'rightTextSize', // 右侧文字大小
  RIGHT_TYPE = 'rightType', // 右侧视图类型
  RIGHT_IMAGE_RESOURCE = 'rightImageResource', // 右侧图标
  RIGHT_IMAGE_WIDTH = 'rightImageWidth', // 右侧图标宽度
  RIGHT_IMAGE_HEIGHT = 'rightImageHeight', // 右侧图标高度
  RIGHT_IMAGE_PADDING = 'rightImagePadding', // 右侧图标padding

  CENTER_LEFT_PADDING = 'centerLeftPadding', // 居中视图左内间距
  CENTER_RIGHT_PADDING = 'centerRightPadding', // 居中视图右内间距
  CENTER_TEXT_COLOR = 'centerTextColor', // 居中文字颜色
  CENTER_TEXT_SIZE = 'centerTextSize', // 居中文字大小
  CENTER_TYPE = 'centerType', // 居中视图类型
  CENTER_IMAGE_RESOURCE = 'centerImageResource', // 居中图标
  CENTER_IMAGE_WIDTH = 'centerImageWidth', // 居中图标宽度
  CENTER_IMAGE_HEIGHT = 'centerImageHeight', // 居中图标高度
  CENTER_IMAGE_PADDING = 'centerImagePadding', // 居中图标padding
}

/**
 * 通用顶部导航栏
 * 作者：https://gitee.com/pzrrzp/hm_common_title_bar
 * */
@Component
export struct TitleBar {
  /**
   * 主体设置
   */
  @StorageProp(TitleGlobalAttribute.IS_FULL_SCREEN) globalIsFullScreen: boolean = true; // 全局设置是否是全面屏
  @StorageProp(TitleGlobalAttribute.STATUS_BAR_HEIGHT) globalStatusBarHeight: Length = 36; // 全局设置状态栏高度
  @StorageProp(TitleGlobalAttribute.TITLE_BAR_HEIGHT) globalTitleBarHeight: Length = 56; // 全局设置标题栏高度,
  @StorageProp(TitleGlobalAttribute.TITLE_BAR_HEIGHT) globalTitleBarRightPadding: Length = 0; // 全局设置标题栏高度,
  @StorageProp(TitleGlobalAttribute.TITLE_BAR_COLOR) globalTitleBarColor: ResourceColor = '#f5f5f5'; // 全局设置标题栏颜色
  @StorageProp(TitleGlobalAttribute.STATUS_BAR_COLOR) globalStatusBarColor: ResourceColor = '#f5f5f5'; // 全局设置状态栏颜色
  @StorageProp(TitleGlobalAttribute.SHOW_BOTTOM_LINE) globalShowBottomLine: boolean = true; // 全局设置是否显示标题栏底部的分割线
  @StorageProp(TitleGlobalAttribute.BOTTOM_LINE_SIZE) globalBottomLineSize: Length = 1; // 全局设置标题栏底部的分割线的宽度
  @StorageProp(TitleGlobalAttribute.BOTTOM_LINE_COLOR) globalBottomLineColor: ResourceColor = '#DDDDDD'; // 全局设置标题栏分割线颜色
  @Prop isFullScreen: boolean =
    this.isFullScreen === undefined ? this.globalIsFullScreen : this.isFullScreen; // 是否是全面屏
  @Prop statusBarHeight: Length =
    this.statusBarHeight === undefined ? this.globalStatusBarHeight : this.statusBarHeight; // 状态栏高度
  @Prop titleBarHeight: Length =
    this.titleBarHeight === undefined ? this.globalTitleBarHeight : this.titleBarHeight; // 自定义标题栏高度,
  @Prop titleBarRightPadding: Length =
    this.titleBarRightPadding === undefined ? this.globalTitleBarRightPadding : this.titleBarRightPadding; // 自定义标题栏右内边距
  @Prop titleBarColor: ResourceColor =
    this.titleBarColor === undefined ? this.globalTitleBarColor : this.titleBarColor; // 标题栏颜色
  @Prop statusBarColor: ResourceColor =
    this.statusBarColor === undefined ? this.globalStatusBarColor : this.statusBarColor; // 状态栏颜色 默认 等于标题栏颜色
  @Prop showBottomLine: boolean =
    this.showBottomLine === undefined ? this.globalShowBottomLine : this.showBottomLine; //  是否显示标题栏底部的分割线
  @Prop bottomLineSize: Length =
    this.bottomLineSize === undefined ? this.globalBottomLineSize : this.bottomLineSize; //  标题栏底部的分割线的宽度
  @Prop bottomLineColor: ResourceColor =
    this.bottomLineColor === undefined ? this.globalBottomLineColor : this.bottomLineColor; // 标题栏分割线颜色
  /**
   * 左侧设置
   */
  @StorageProp(TitleGlobalAttribute.LEFT_TYPE) globalLeftType: string = TitleType.IMAGE; // 全局设置左侧视图类型
  @StorageProp(TitleGlobalAttribute.LEFT_LEFT_PADDING) globalLeftLeftPadding: Length = 15; // 全局设置左侧视图左内间距
  @StorageProp(TitleGlobalAttribute.LEFT_RIGHT_PADDING) globalLeftRightPadding: Length = 5; // 全局设置左侧视图右内间距
  @StorageProp(TitleGlobalAttribute.LEFT_TEXT_COLOR) globalLeftTextColor: ResourceColor = '#000000'; // 全局设置左侧文字颜色
  @StorageProp(TitleGlobalAttribute.LEFT_TEXT_SIZE) globalLeftTextSize: Length = 16; // 全局设置左侧文字大小
  @StorageProp(TitleGlobalAttribute.LEFT_TEXT_SIZE) globalLeftTextWeight: string | number | FontWeight = FontWeight.Normal; // 全局设置左侧文字字重
  @StorageProp(TitleGlobalAttribute.LEFT_IMAGE_RESOURCE) globalLeftImageResource: ResourceStr | PixelMap =
    $r('app.media.ic_public_arrow_left'); // 全局设置左侧图标
  @StorageProp(TitleGlobalAttribute.LEFT_IMAGE_WIDTH) globalLeftImageWidth: Length = 26; // 全局设置左侧图标宽度
  @StorageProp(TitleGlobalAttribute.LEFT_IMAGE_HEIGHT) globalLeftImageHeight: Length = 26; // 全局设置左侧图标高度
  @StorageProp(TitleGlobalAttribute.LEFT_IMAGE_PADDING) globalLeftImagePadding: Length = 5; // 全局设置左侧图标padding
  @Prop leftType: string =
    this.leftType === undefined ? this.globalLeftType : this.leftType; // 左侧视图类型：空白|文字|图标|自定义视图，默认显示返回按钮
  @Prop leftWidth: Length = -1; // 左侧视图宽度，不设置则自适应内容
  @Prop leftLeftPadding: Length =
    this.leftLeftPadding === undefined ? this.globalLeftLeftPadding : this.leftLeftPadding; // 左侧视图左内间距
  @Prop leftRightPadding: Length =
    this.leftRightPadding === undefined ? this.globalLeftRightPadding : this.leftRightPadding; // 左侧视图右内间距
  @Prop leftText: ResourceStr = 'Left'; // 左侧文字leftType = text 有效
  @Prop leftTextColor: ResourceColor =
    this.leftTextColor === undefined ? this.globalLeftTextColor : this.leftTextColor; // 左侧文字颜色
  @Prop leftTextSize: Length = this.leftTextSize === undefined ? this.globalLeftTextSize : this.leftTextSize; // 左侧文字大小
  @Prop leftTextWeight: string | number | FontWeight = this.leftTextWeight === undefined ? this.globalLeftTextWeight : this.leftTextWeight; // 左侧文字大小
  @Prop leftTextOverflow: TextOverflow =
    TextOverflow.MARQUEE; // 左侧文本，超长时的显示方式，默认跑马灯效果；None：文本超长时按最大行截断显示；Clip：文本超长时按最大行截断显示；Ellipsis：文本超长时显示不下的文本用省略号代替；MARQUEE：文本超长时以跑马灯的方式展示
  @Prop leftImageResource: ResourceStr | PixelMap =
    this.leftImageResource === undefined ? this.globalLeftImageResource :
    this.leftImageResource // 左侧图标：默认返回图标，leftType = image
  @Prop leftImageWidth: Length =
    this.leftImageWidth === undefined ? this.globalLeftImageWidth : this.leftImageWidth; // 左侧图标宽度
  @Prop leftImageHeight: Length =
    this.leftImageHeight === undefined ? this.globalLeftImageHeight : this.leftImageHeight; // 左侧图标高度
  @Prop leftImagePadding: Length = this.leftImagePadding === undefined ? this.globalLeftImagePadding :
  this.leftImagePadding; // 左侧图标padding值：图标尺寸16，内间距各5，保证点击范围
  @Prop leftBackType: string = BackType.ROUTER; // 返回方法
  @Prop leftBackFillColor: ResourceColor = ''
  @Prop leftPopToName: string = ''; // NavPathStack.popToName('name') 方式的页面名称
  @Prop leftPopToIndex: number = 0; // NavPathStack.popToIndex(1) 方式的索引
  @BuilderParam leftCustomView: () => void; // 左侧自定义View
  leftOnClick?: () => void; // 左侧点击事件
  /**
   * 右侧设置
   */
  @StorageProp(TitleGlobalAttribute.RIGHT_TYPE) globalRightType: string = TitleType.NONE; // 全局设置右侧视图类型
  @StorageProp(TitleGlobalAttribute.RIGHT_LEFT_PADDING) globalRightLeftPadding: Length = 5; // 全局设置右侧视图左内间距
  @StorageProp(TitleGlobalAttribute.RIGHT_RIGHT_PADDING) globalRightRightPadding: Length = 15; // 全局设置右侧视图右内间距
  @StorageProp(TitleGlobalAttribute.RIGHT_TEXT_COLOR) globalRightTextColor: ResourceColor = '#000000'; // 全局设置右侧文字颜色
  @StorageProp(TitleGlobalAttribute.RIGHT_TEXT_SIZE) globalRightTextSize: Length = 16; // 全局设置右侧文字大小
  @StorageProp(TitleGlobalAttribute.RIGHT_IMAGE_RESOURCE) globalRightImageResource: ResourceStr | PixelMap =
    $r('app.media.ic_public_more'); // 全局设置右侧图标
  @StorageProp(TitleGlobalAttribute.RIGHT_IMAGE_WIDTH) globalRightImageWidth: Length = 26; // 全局设置右侧图标宽度
  @StorageProp(TitleGlobalAttribute.RIGHT_IMAGE_HEIGHT) globalRightImageHeight: Length = 26; // 全局设置右侧图标高度
  @StorageProp(TitleGlobalAttribute.RIGHT_IMAGE_PADDING) globalRightImagePadding: Length = 5; // 全局设置右侧图标padding
  @Prop rightType: string =
    this.rightType === undefined ? this.globalRightType : this.rightType; // 右侧视图类型：空白|文字|图标|自定义视图，默认无视图
  @Prop rightWidth: Length = -1; // 右侧宽度，不设置则自适应内容
  @Prop rightLeftPadding: Length =
    this.rightLeftPadding === undefined ? this.globalRightLeftPadding : this.rightLeftPadding; // 右侧视图左间距
  @Prop rightRightPadding: Length =
    this.rightRightPadding === undefined ? this.globalRightRightPadding : this.rightRightPadding; // 右侧视图右间距
  @Prop rightText: ResourceStr = 'Right'; // 右侧文字leftType = text 有效
  @Prop rightTextColor: ResourceColor =
    this.rightTextColor === undefined ? this.globalRightTextColor : this.rightTextColor; // 右侧文字颜色
  @Prop rightTextSize: Length =
    this.rightTextSize === undefined ? this.globalRightTextSize : this.rightTextSize; // 右侧文字大小
  @Prop rightTextOverflow: TextOverflow =
    TextOverflow.MARQUEE; // 右侧文本，超长时的显示方式，默认跑马灯效果；None：文本超长时按最大行截断显示；Clip：文本超长时按最大行截断显示；Ellipsis：文本超长时显示不下的文本用省略号代替；MARQUEE：文本超长时以跑马灯的方式展示
  rightOnClick?: (item?: MenuItemOptions, index?: number) => void; // 右侧点击事件
  @Prop rightImageResource: ResourceStr | PixelMap =
    this.rightImageResource === undefined ? this.globalRightImageResource :
    this.rightImageResource; // 右侧图标：默认更多图标，rightType = image
  @BuilderParam rightMorePopupView: () => void = this.baseMorePopupView; // 如果默认使用更多图标，可默认展示气泡菜单右侧View
  @State handlePopup: boolean = false
  @Prop rightMorePopupData: MenuItemOptions[]
  @Prop rightImageWidth: Length =
    this.rightImageWidth === undefined ? this.globalRightImageWidth : this.rightImageWidth; // 右侧图标宽度
  @Prop rightImageHeight: Length =
    this.rightImageHeight === undefined ? this.globalRightImageHeight : this.rightImageHeight; // 右侧图标高度
  @Prop rightImagePadding: Length = this.rightImagePadding === undefined ? this.globalRightImagePadding :
  this.rightImagePadding; // 右侧图标padding值：图标尺寸16，内间距各5，保证点击范围
  @BuilderParam rightCustomView: () => void; // 右侧自定义View
  /**
   * 居中设置
   */
  @StorageProp(TitleGlobalAttribute.CENTER_TYPE) globalCenterType: string = TitleType.TEXT; // 全局设置居中视图类型
  @StorageProp(TitleGlobalAttribute.CENTER_LEFT_PADDING) globalCenterLeftPadding: Length = 30; // 全局设置居中视图左内间距
  @StorageProp(TitleGlobalAttribute.CENTER_RIGHT_PADDING) globalCenterRightPadding: Length = 30; // 全局设置居中视图右内间距
  @StorageProp(TitleGlobalAttribute.CENTER_TEXT_COLOR) globalCenterTextColor: ResourceColor = '#000000'; // 全局设置居中文字颜色
  @StorageProp(TitleGlobalAttribute.CENTER_TEXT_SIZE) globalCenterTextSize: Length = 16; // 全局设置居中文字大小
  @StorageProp(TitleGlobalAttribute.CENTER_IMAGE_RESOURCE) globalCenterImageResource: ResourceStr | PixelMap =
    $r('app.media.ic_public_more'); // 全局设置右侧图标
  @StorageProp(TitleGlobalAttribute.CENTER_IMAGE_WIDTH) globalCenterImageWidth: Length = 26; // 全局设置居中图标宽度
  @StorageProp(TitleGlobalAttribute.CENTER_IMAGE_HEIGHT) globalCenterImageHeight: Length = 26; // 全局设置居中图标高度
  @StorageProp(TitleGlobalAttribute.CENTER_IMAGE_PADDING) globalCenterImagePadding: Length = 5; // 全局设置居中图标padding
  @Prop centerType: string =
    this.centerType === undefined ? this.globalCenterType : this.centerType; // 居中视图类型：无|文字|按钮|自定义视图，默认文字视图
  @Prop centerWidth: Length = -1; // 居中宽度，不设置则自适应内容
  @Prop centerText: ResourceStr = ''; // 居中文字leftType= text 有效
  @Prop centerTextColor: ResourceColor =
    this.centerTextColor === undefined ? this.globalCenterTextColor : this.centerTextColor; // 居中文字颜色
  @Prop centerTextSize: Length =
    this.centerTextSize === undefined ? this.globalCenterTextSize : this.centerTextSize; // 居中文字大小
  @Prop centerTextOverflow: TextOverflow =
    TextOverflow.MARQUEE; // 居中文本，超长时的显示方式，默认跑马灯效果；None：文本超长时按最大行截断显示；Clip：文本超长时按最大行截断显示；Ellipsis：文本超长时显示不下的文本用省略号代替；MARQUEE：文本超长时以跑马灯的方式展示
  centerOnClick?: () => void; //  居中文字点击事件
  @Prop centerImageResource: ResourceStr | PixelMap =
    this.centerImageResource === undefined ? this.globalCenterImageResource : this.centerImageResource; // 居中图片
  @Prop centerImageWidth: Length =
    this.centerImageWidth === undefined ? this.globalCenterImageWidth : this.centerImageWidth; // 居中图标宽度
  @Prop centerImageHeight: Length =
    this.centerImageHeight === undefined ? this.globalCenterImageHeight : this.centerImageHeight; // 居中图标高度
  @Prop centerImagePadding: Length = this.centerImagePadding === undefined ? this.globalCenterImagePadding :
  this.centerImagePadding; // 居中图标padding值：图标尺寸16，内间距各5，保证点击范围
  @BuilderParam centerCustomView: () => void; // 居中自定义View
  @Prop searchValue: string; // 居中搜索框文本
  @Prop searchPlaceholder: ResourceStr = '请输入关键字'; // 居中搜索框提示文本
  @Prop searchButtonText: string = '搜索'; // 设置搜索框末尾搜索按钮文本
  searchButtonOptions?: SearchButtonOptions; // 设置搜索框末尾搜索按钮文本
  onSubmitSearch?: (value: string) => void; // 点击搜索图标、搜索按钮或者按下软键盘搜索按钮时触发该回调
  onChangeSearch?: (value: string) => void; // 输入内容发生变化时，触发该回调
  @Prop centerLeftPadding: Length =
    this.centerLeftPadding ? this.globalCenterLeftPadding : this.centerLeftPadding; // 居中视图左间距
  @Prop centerRightPadding: Length =
    this.centerRightPadding ? this.globalCenterRightPadding : this.centerRightPadding; // 居中视图右间距

  aboutToAppear(): void {
    if (this.statusBarColor === undefined) {
      this.statusBarColor = this.titleBarColor
    }
  }

  @Builder
  baseMorePopupView() {
    Menu() {
      ForEach(this.rightMorePopupData, (item: MenuItemOptions, index: number) => {
        MenuItem({
          startIcon: item.startIcon,
          content: item.content,
          endIcon: item.endIcon,
          labelInfo: item.labelInfo,
          builder: item.builder
        })
          .onClick(() => {
            if (this.rightOnClick) {
              this.rightOnClick(item, index)
            }
            this.handlePopup = false
          })
      })

    }
  }

  build() {
    Column() {
      /*Row()
        .width('100%')
        .height(this.statusBarHeight)
        .backgroundColor(this.statusBarColor)
        .visibility(this.isFullScreen ? Visibility.Visible : Visibility.None)*/

      RelativeContainer() {
        /**
         * 居中
         */
        Row() {
          /**
           * 居中文本
           */
          Text(this.centerText)
            .fontColor(this.centerTextColor)
            .fontSize(this.centerTextSize)
            .maxLines(1)
            .onClick(() => {
              if (this.centerOnClick !== undefined) {
                this.centerOnClick();
              }
            })
            .textOverflow({ overflow: this.centerTextOverflow })
            .visibility(this.centerType === TitleType.TEXT ? Visibility.Visible : Visibility.None)
          /**
           * 居中图标
           */
          Image(this.centerImageResource)
            .width(this.rightImageWidth)
            .height(this.rightImageHeight)
            .padding(this.rightImagePadding)
            .onClick(() => {
              if (this.centerOnClick !== undefined) {
                this.centerOnClick();
              }
            })
            .visibility(this.centerType === TitleType.IMAGE ? Visibility.Visible : Visibility.None)
          /**
           * 居中自定义
           */
          Column() {
            if (this.centerCustomView) {
              this.centerCustomView()
            }
          }
          .visibility(this.centerType === TitleType.CUSTOM ? Visibility.Visible : Visibility.None)

          /**
           * 居中搜索框
           */
          Column() {
            Search({
              value: this.searchValue,
              placeholder: this.searchPlaceholder,
            })
              .height(38)
              .defaultFocus(true)
              .searchButton(this.searchButtonText, this.searchButtonOptions)
              .onSubmit((value: string) => {
                if (this.onSubmitSearch) {
                  this.onSubmitSearch(value);
                }
              })
              .onChange((value: string) => {
                if (this.onChangeSearch) {
                  this.onChangeSearch(value);
                }
              })
          }
          .visibility(this.centerType === TitleType.SEARCH ? Visibility.Visible : Visibility.None)
        }
        .layoutWeight(1)
        .padding({
          left: this.centerLeftPadding,
          right: this.centerRightPadding,
        })
        .justifyContent(FlexAlign.Center)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          left: { anchor: '__container__', align: HorizontalAlign.Start },
          right: { anchor: '__container__', align: HorizontalAlign.End }
        })
        .height('100%')
        .width(this.centerWidth)
        .id('center')

        /**
         * 左侧
         */
        Row() {
          /**
           * 左侧文本
           */
          Text(this.leftText)
            .fontColor(this.leftTextColor)
            .fontSize(this.leftTextSize)
            .fontWeight(this.leftTextWeight)
            .maxLines(1)
            .onClick(() => {
              if (this.leftOnClick !== undefined) {
                this.leftOnClick();
              }
            })
            .textOverflow({ overflow: this.leftTextOverflow })
            .visibility(this.leftType === TitleType.TEXT ? Visibility.Visible : Visibility.None)
          /**
           * 左侧图标
           */
          Image(this.leftImageResource)
            .width(this.leftImageWidth)
            .height(this.leftImageHeight)
            .padding(this.leftImagePadding)
            .fillColor(this.leftBackFillColor)
            .onClick(() => {
              if (this.leftOnClick !== undefined) { // 自定义了点击事件
                this.leftOnClick();
              } else { // 没有自定义点击事件，点击则默认返回
                if (this.leftBackType === BackType.NONE) {
                  LogUtil.info('左侧返回')
                } else if (this.leftBackType === BackType.ROUTER) {
                  router.back()
                }
              }
            })
            .visibility(this.leftType === TitleType.IMAGE ? Visibility.Visible : Visibility.None)
          /**
           * 左侧自定义视图
           */
          Column() {
            if (this.leftCustomView) {
              this.leftCustomView()
            }
          }
          .visibility(this.leftType === TitleType.CUSTOM ? Visibility.Visible : Visibility.None)
        }
        .padding({
          left: this.leftLeftPadding,
          right: this.leftRightPadding
        })
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          left: { anchor: '__container__', align: HorizontalAlign.Start }
        })
        .width(this.leftWidth)
        .height('100%')
        .id('left')

        /**
         * 右侧
         */
        Row() {
          /**
           * 右侧文本
           */
          Text(this.rightText)
            .fontColor(this.rightTextColor)
            .fontSize(this.rightTextSize)// .width(this.rightTextWidth)
            .maxLines(1)
            .onClick(() => {
              if (this.rightOnClick !== undefined) {
                this.rightOnClick();
              }
            })
            .textOverflow({ overflow: this.rightTextOverflow })
            .visibility(this.rightType === TitleType.TEXT ? Visibility.Visible : Visibility.None)
          /**
           * 右侧图标
           */
          Image(this.rightImageResource)
            .width(this.rightImageWidth)
            .height(this.rightImageHeight)
            .padding(this.rightImagePadding)
            .onClick(() => {
              if (this.rightMorePopupData !== undefined) {
                this.handlePopup = !this.handlePopup
              } else {
                if (this.rightOnClick !== undefined) {
                  this.rightOnClick();
                }
              }
            })
            .bindPopup(this.handlePopup, {
              builder: this.rightMorePopupView, // 气泡的内容
              placement: Placement.Bottom, // 气泡的弹出位置
              onStateChange: (e) => {
                if (!e.isVisible) {
                  this.handlePopup = false
                }
              }
            })
            .visibility(this.rightType === TitleType.IMAGE ? Visibility.Visible : Visibility.None)
          /**
           * 右侧自定义
           */
          Column() {
            if (this.rightCustomView) {
              this.rightCustomView()
            }
          }.visibility(this.rightType === TitleType.CUSTOM ? Visibility.Visible : Visibility.None)
        }
        .padding({
          left: this.rightLeftPadding,
          right: this.rightRightPadding
        })
        .height('100%')
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          right: { anchor: '__container__', align: HorizontalAlign.End }
        })
        .width(this.rightWidth)
        .id('right')

      }
      .width('100%')
      .padding({right: this.titleBarRightPadding})
      .height(this.titleBarHeight)
      .backgroundColor(this.titleBarColor)
      .border({
        width: { bottom: this.showBottomLine ? this.bottomLineSize : '0' },
      })
      .borderColor(this.bottomLineColor)
    }.justifyContent(FlexAlign.Center)

  }
}
