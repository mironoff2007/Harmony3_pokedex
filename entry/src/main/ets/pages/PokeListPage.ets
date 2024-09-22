import { PokeListViewModel } from '../viewmodel/PokeListViewModel';

let storage: LocalStorage = new LocalStorage();
let pokeListViewModel: PokeListViewModel = new PokeListViewModel(storage)

@Entry
@Component
struct PokeListPage {
  @State message: string = 'PokeListPage';

  build() {
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
    .onAppear(() => {
      console.log('on appear')
      pokeListViewModel.callPokemonsFromServer()
    })
  }
}