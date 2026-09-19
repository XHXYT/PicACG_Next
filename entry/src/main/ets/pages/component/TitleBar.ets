import { PicState } from "../../entryability/AppState";


/**
 * 视图类型
 */
export enum TitleType {
  NONE = 'none',    // 空
  TEXT = 'text',    // 文字
  IMAGE = 'image',  // 图标
  CUSTOM = 'custom' // 自定义
}

/**
 * 标题位置
 */
export enum TitleTextPosition {
  LEFT = 'left',    // 左对齐：标题跟在左侧按钮之后
  CENTER = 'center' // 居中
}

/**
 * 通用顶部导航栏
 */
@ComponentV2
export struct TitleBar {
  // --- 主配置 ---
  // title 保持响应式（阅读器切换章节时父组件会更新）
  @Param title: string = '';
  // 其余均为创建时一次性配置：@Once 只在初始化时同步一次，之后不再追踪父组件变化
  @Param @Once titlePosition: TitleTextPosition = TitleTextPosition.CENTER; // 标题位置
  @Param @Once bgColor: ResourceColor = $r('app.color.start_window_background'); // 背景色（与页面背景一致，跟随深浅色）
  @Param @Once barHeight: number = 56;             // 高度
  @Param @Once showBottomLine: boolean = true;  // 是否显示底部线条

  // --- 左侧配置 (默认显示返回按钮) ---
  @Param @Once leftType: TitleType = TitleType.IMAGE;
  @Param @Once leftText: string = '返回';
  @Param @Once leftIcon: ResourceStr = $r('app.media.ic_public_arrow_left');
  @Param @Once leftIconColor: ResourceColor = $r('sys.color.font_primary'); // 图标颜色（跟随深浅色）
  @Event onLeftClick?: () => void = undefined;        // 左侧点击事件

  // --- 右侧配置 (默认不显示) ---
  @Param @Once rightType: TitleType = TitleType.NONE;
  @Param @Once rightText: string = '';
  @Param @Once rightIcon: ResourceStr = $r('app.media.ic_public_more');
  @Param @Once rightMenuData?: MenuItemOptions[] = undefined
  @Event onRightClick?: () => void;       // 右侧点击事件

  // --- 自定义视图插槽 ---
  @BuilderParam leftCustomView: () => void = this.defaultBuilder;
  @BuilderParam centerCustomView: () => void = this.defaultBuilder;
  @BuilderParam rightCustomView: () => void = this.defaultBuilder;

  // --- 内部状态 ---
  @Local showMenu: boolean = false;

  @Builder
  defaultBuilder() {}

  build() {
    RelativeContainer() {
      // 左侧区域
      Row() {
        if (this.leftType === TitleType.CUSTOM) {
          this.leftCustomView();
        } else if (this.leftType === TitleType.IMAGE) {
          Button() {
            Image(this.leftIcon)
              .width(26)
              .height(26)
              .fillColor(this.leftIconColor)
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => this.handleLeftClick());
        } else if (this.leftType === TitleType.TEXT) {
          Text(this.leftText)
            .fontSize(16)
            .onClick(() => this.handleLeftClick());
        }

        // 左对齐标题：跟在左侧按钮之后
        if (this.titlePosition === TitleTextPosition.LEFT && this.title) {
          Text(this.title)
            .fontSize(18)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ left: this.leftType === TitleType.NONE ? 0 : 10 });
        }
      }
      .id('tbLeft')
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 15, right: 5 })
      .constraintSize({ maxWidth: '70%' })
      .alignRules({
        left: { anchor: '__container__', align: HorizontalAlign.Start },
        center: { anchor: '__container__', align: VerticalAlign.Center }
      })

      // 中间区域
      Row() {
        if (this.titlePosition === TitleTextPosition.CENTER && this.title) {
          Text(this.title)
            .fontSize(18)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        } else {
          this.centerCustomView()
        }
      }
      .id('tbCenter')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .constraintSize({ maxWidth: '60%' })
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        center: { anchor: '__container__', align: VerticalAlign.Center }
      })

      // 右侧区域
      Row() {
        if (this.rightType === TitleType.CUSTOM) {
          this.rightCustomView();
        } else if (this.rightType === TitleType.IMAGE) {
          Image(this.rightIcon)
            .width(26)
            .height(26)
            .onClick(() => {
              if (this.rightMenuData && this.rightMenuData.length > 0) {
                this.showMenu = true;
              } else {
                this.onRightClick?.();
              }
            })
            .bindPopup((this.showMenu && this.rightMenuData !== undefined), {
              builder: this.MenuBuilder,
              placement: Placement.Bottom,
              onStateChange: (e) => { if (!e.isVisible) this.showMenu = false; }
            });
        } else if (this.rightType === TitleType.TEXT) {
          Text(this.rightText)
            .fontSize(16)
            .onClick(() => this.onRightClick?.());
        }
      }
      .id('tbRight')
      .justifyContent(FlexAlign.End)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 5, right: 15 })
      .alignRules({
        right: { anchor: '__container__', align: HorizontalAlign.End },
        center: { anchor: '__container__', align: VerticalAlign.Center }
      })
    }
    .width('100%')
    .height(this.barHeight)
    .backgroundColor(this.bgColor)
    .border({
      width: { bottom: this.showBottomLine ? 0.5 : 0 },
      color: $r('sys.color.comp_divider')
    })
  }

  @Builder MenuBuilder() {
    Menu() {
      ForEach(this.rightMenuData || [], (item: MenuItemOptions, index: number) => {
        MenuItem(item)
          .onClick(() => {
            this.onRightClick?.(); // 触发外部事件
            this.showMenu = false;
          })
      })
    }
  }

  // 统一处理左侧点击逻辑
  private handleLeftClick() {
    if (this.onLeftClick) {
      this.onLeftClick();
    } else {
      PicState.pageStack.pop(true)
    }
  }

}

/**
 * 设置页专用标题栏
 */
@ComponentV2
export struct SettingsTitleBar {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param showBack: boolean = false;
  @Param navPathStack: NavPathStack | null = null;

  build() {
    Row({ space: 5 }) {
      if (this.showBack) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontColor([$r('sys.color.font_primary')])
            .fontSize(25)
        }
        .margin({ left: 16 })
        .width(40)
        .height(40)
        .backgroundColor($r('sys.color.button_background_color_transparent'))
        .onClick(() => {
          // 安全调用
          if (this.navPathStack) {
            this.navPathStack.pop(true);
          }
        })
      }

      // 标题区与返回按钮同高（40），内容垂直居中，保证标题与按钮中线对齐
      Column() {
        Text(this.title)
          .fontSize(20)
          .fontColor($r('app.color.common_button_background_light'))
          .fontWeight(FontWeight.Bold)

        if (this.subtitle) {
          Text(this.subtitle)
            .maxLines(1)
            .fontSize(12)
            .fontColor($r('app.color.common_button_background_light'))
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .height(40)
      .layoutWeight(1)
      .margin({ left: this.showBack ? 3 : 16 })
    }
    .alignItems(VerticalAlign.Bottom)
    .margin({ bottom: 10 })
    .width('100%')
    .height(56)
  }

}
