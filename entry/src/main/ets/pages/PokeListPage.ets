import ArrayList from '@ohos.util.ArrayList';
import { ViewState } from '../common/State';
import { Pokemon } from '../model/Pokemon';
import { PokeListViewModel } from '../viewmodel/pokelist/PokeListViewModel';
import Curves from '@ohos.curves'

let storage: LocalStorage = new LocalStorage();
let pokeListViewModel: PokeListViewModel = new PokeListViewModel(storage)

@Entry(storage)
@Component
struct PokeListPage {
  @State message: string = 'PokeListPage';
  @State progressVal: number = 0;
  @State isLoading: boolean = true;
  @State intervalLoading: number = -1;

  @LocalStorageProp('pokeListState')
  @Watch('onStateChange')
  state: ViewState<ArrayList<Pokemon>> = ViewState.loading;

  @State private progress: number = 0
  private curve1 = Curves.cubicBezier(0.4, 0, 1, 1)

  // @Watch callback
  onStateChange(): void {
    if (ViewState.isLoading(this.state)) {

    }  else if (ViewState.isContent(this.state)) {

    }
  }

  aboutToAppear() {
    pokeListViewModel.getPokemons()
    this.intervalLoading = setInterval(() => {
      this.progressVal = this.progressVal >= 100 ?
        0 : (this.progressVal + 5);
    }, 50);
  }

  build() {
    if (ViewState.isLoading(this.state)) {
      Stack({ alignContent: Alignment.Center }) {
        Progress({ value: 0, total: 100, type: ProgressType.Ring })
          .width(100)
          .value(this.progressVal)
      }.width('100%').height('100%')
    } else if (ViewState.isContent(this.state)) {
      Column() {
        Text(this.message)
          .id('PokeListPage')
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
        Image("https://plus.unsplash.com/premium_photo-1683865776032-07bf70b0add1?q=80&w=1932&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")
          .width(200).borderWidth(2)
        Text(this.message)
          .id('PokeListPage')
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
      }
      .height('100%')
      .width('100%')
    } else {

    }
  }
}