import { ComicCardInterface } from '../../common/Model'
import ComicCard from './ComicCard'


@ComponentV2
export default struct ComicCardScroll {

  @Param @Require comics: ComicCardInterface[]
  @Event onCardClick: (comic: ComicCardInterface) => void

  build() {
    Column() {
      List({ space: 10 }) {
        ForEach(this.comics, (comic: ComicCardInterface, index: number) => {
          ListItem() {
            ComicCard({
              comic: comic,
              onCardClick: (comic) => {
                this.onCardClick(comic)
              }
            })
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