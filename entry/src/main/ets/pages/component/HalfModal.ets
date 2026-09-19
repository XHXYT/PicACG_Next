@ComponentV2
export default struct HalfModal {
  @Param @Require show: boolean
  @Param @Require options: SheetOptions
  @BuilderParam view: () => void

  build() {
    Flex()
      .width(0)
      .height(0)
      .borderRadius({ topRight: 30, bottomRight: 30 })
      .bindSheet(this.show, this.view(), this.options)
  }
}