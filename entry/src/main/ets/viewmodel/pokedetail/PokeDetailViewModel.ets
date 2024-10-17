import { PokeDetailState } from './PokeDetailState';
import { ViewState } from '../../common/State';
import { PokeRepo } from '../../db/PokeRepo';
import { ViewModel } from '../../common/ViewModel';

export class PokeDetailViewModel extends ViewModel {
  LOG_TAG: string = "PokeDetailViewModel-"

  pokeRepo = new PokeRepo();

  private setError(e) {
    try {
      const setResult = this.storage.set<ViewState<PokeDetailState>>("pokeDetailState", ViewState.error(e));
      console.log("setResult-" + setResult);
    } catch (e) {
      console.error(e)
    }
  }

  getPokemon(name: string) {
    this.backgroundTask(this.getPokemonTask(name))
  }

  private async getPokemonTask(name: string) {
    try {
      const poke = await this.pokeRepo.getByName(name)
      const setResult = this.storage.set<ViewState<PokeDetailState>>("pokeDetailState", ViewState.content({pokemon: poke}));
      console.log("setResult-" + setResult);
    } catch (e) {
      this.setError(e)
      console.error(this.LOG_TAG + `error get: ${e}`);
    }
  }

}