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
  state: ViewState<Array<Pokemon>> = ViewState.loading;

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
      Stack() {
        List() {
          ForEach(this.state.value, (item: Pokemon) => {
            ListItem() {
              Row() {
                Text(item.name)
              }
            }
          }, (item, index) => index + JSON.stringify(item));
        }
        .width('100%')
        .divider({
          strokeWidth: '0.5vp',
          color: '#0D000000'
        })
      }
      .height('100%')
      .width('100%')
    } else {

    }
  }
}