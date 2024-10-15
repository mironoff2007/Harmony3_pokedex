import { ViewState } from '../common/State';
import { Pokemon } from '../model/Pokemon';
import { PokeListViewModel } from '../viewmodel/pokelist/PokeListViewModel';
import { PokeListState } from '../viewmodel/pokelist/PokeListState';
import { RouteConstants } from './RouteConstants';
import router from '@ohos.router';
import { PokeDetailParams } from '../viewmodel/pokedetail/PokeDetailParams';
import { PokeListAdapter } from '../viewmodel/pokelist/PokeListAdapter';

let storage: LocalStorage = new LocalStorage();
const pokeListViewModel: PokeListViewModel = new PokeListViewModel(storage)

@Entry(storage)
@Component
struct PokeListPage {
  @State message: string = 'PokeListPage';
  @State progressVal: number = 0;
  @State isLoading: boolean = true;
  @State intervalLoading: number = -1;

  @LocalStorageProp('pokeListState')
  @Watch('onStateChange')
  state: ViewState<PokeListState> = ViewState.loading;

  @LocalStorageProp('pokeUpdate')
  @Watch('onPokeUpdate')
  updatePokemon: Pokemon = null;

  private listAdapter: PokeListAdapter = new PokeListAdapter();

  // @Watch callback
  onStateChange(): void {
    if (ViewState.isLoading(this.state)) {

    } else if (ViewState.isContent(this.state)) {
        this.listAdapter.addAllData(this.state.value.lastPokemons)
    }
  }

  // @Watch callback
  onPokeUpdate(): void {
    if (this.updatePokemon != null) {
      this.listAdapter.updateData(this.updatePokemon.id, this.updatePokemon)
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
          LazyForEach(this.listAdapter, (item: Pokemon) => {
            ListItem() {
              Row() {
                Text(item.name)
                  .fontSize(40)
                  .fontWeight(FontWeight.Bold)
                if (item.picUrl.length != 0) {
                  Image(item.picUrl)
                    .height(120)
                    .objectFit(ImageFit.Fill)
                } else {
                  Progress({ value: 0, total: 100, type: ProgressType.Ring })
                    .width(20)
                    .value(this.progressVal)
                }
              }
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .height(120)
              .width('100%')
              .onAppear(() => {
                console.info("draw-" + item.name)
                if (item.picUrl == "") {
                  pokeListViewModel.getPokeInfo(item)
                }
              })
            }
            .width('100%')
            .onClick(()=>{
              console.info("click poke-" + item.name)
              const params: PokeDetailParams = { name: item.name }
              router.pushUrl({ url: RouteConstants.POKE_DETAILS, params: params })
            })
          }, (item, index) => index + JSON.stringify(item));
        }
        .width('100%')
        .height('100%')
        .divider({
          strokeWidth: '0.5vp',
          color: '#0D000000'
        })
      }
      .height('100%')
      .width('100%')
    } else if (ViewState.isError(this.state)) {
      Stack({ alignContent: Alignment.Center }) {
        Text("Error-" + this.state.err)
      }.width('100%').height('100%')
    } else {

    }
  }
}