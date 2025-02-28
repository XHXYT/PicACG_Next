import ComicCard, { ComicCardInterface } from './ComicCard'

@Component
export default struct ComicCardScroll {
  @Prop comics: ComicCardInterface[]

  build() {
    Column() {
      List({ space: 10 }) {
        ForEach(this.comics, (comic: ComicCardInterface, index: number) => {
          ListItem() {
            ComicCard({ comic: comic })
          }
          .transition(TransitionEffect.move(TransitionEdge.END))
        })
      }
      .width('100%')
      .height(220)
      .scrollBar(BarState.Off)
      .listDirection(Axis.Horizontal)
    }
  }
}