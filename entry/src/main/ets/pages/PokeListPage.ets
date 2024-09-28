import { ViewState } from '../common/State';
import { Pokemon } from '../model/Pokemon';
import { PokeListViewModel } from '../viewmodel/pokelist/PokeListViewModel';
import Curves from '@ohos.curves'

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
  state: ViewState<Array<Pokemon>> = ViewState.loading;
  private data: PokeDataSource = new PokeDataSource();

  // @Watch callback
  onStateChange(): void {
    if (ViewState.isLoading(this.state)) {

    }  else if (ViewState.isContent(this.state)) {
          this.data.addAllData(this.state.value)
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
          LazyForEach(this.data, (item: Pokemon) => {
            ListItem() {
              Row() {
                Text(item.name)
                  .fontSize(30)
                  .fontWeight(FontWeight.Bold)
                  .alignRules({
                    center: { anchor: '__container__', align: VerticalAlign.Center },
                    middle: { anchor: '__container__', align: HorizontalAlign.Center }
                  })
                if (item.picUrl.length != 0) {
                  Image(item.picUrl)
                    .height(150)
                    .objectFit(ImageFit.Fill)
                } else {
                  Progress({ value: 0, total: 100, type: ProgressType.Ring })
                    .width(20)
                    .value(this.progressVal)
                }
              }
              .height(150)
              .onAppear(() => {
                console.info("draw-" + item.name)
                pokeListViewModel.getPokeInfo(item)
              })
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
    } else if (ViewState.isError(this.state)) {
      Stack({ alignContent: Alignment.Center }) {
        Text("Error-" + this.state.err)
      }.width('100%').height('100%')
    } else {

    }
  }
}

// Basic implementation of IDataSource to handle data listener
class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private originDataArray: Pokemon[] = [];

  public totalCount(): number {
    return 0;
  }

  public getData(index: number): Pokemon {
    return this.originDataArray[index];
  }

  // This method is called by the framework to add a listener to the LazyForEach data source.
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      console.info('add listener');
      this.listeners.push(listener);
    }
  }

  // This method is called by the framework to remove the listener from the LazyForEach data source.
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      console.info('remove listener');
      this.listeners.splice(pos, 1);
    }
  }

  // Notify LazyForEach that all child components need to be reloaded.
  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  // Notify LazyForEach that a child component needs to be added for the data item with the specified index.
  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    })
  }

  // Notify LazyForEach that the data item with the specified index has changed and the child component needs to be rebuilt.
  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index);
    })
  }

  // Notify LazyForEach that the child component that matches the specified index needs to be deleted.
  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index);
    })
  }

  // Notify LazyForEach that data needs to be swapped between the from and to positions.
  notifyDataMove(from: number, to: number): void {
    this.listeners.forEach(listener => {
      listener.onDataMove(from, to);
    })
  }
}

class PokeDataSource extends BasicDataSource {
  private dataArray: Pokemon[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): Pokemon {
    return this.dataArray[index];
  }

  public addData(index: number, data: Pokemon): void {
    this.dataArray.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  public pushData(data: Pokemon): void {
    this.dataArray.push(data);
    this.notifyDataReload()
    this.notifyDataAdd(this.dataArray.length - 1);
  }

  public addAllData(array: Array<Pokemon>): void {
    this.dataArray.splice(0, this.dataArray.length)
    array.forEach((data) => {
      this.dataArray.push(data);
    })
    this.notifyDataReload()
  }
}
