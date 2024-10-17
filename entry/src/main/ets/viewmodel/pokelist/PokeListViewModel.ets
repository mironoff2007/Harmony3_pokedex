import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import http from '@ohos.net.http';

import { store } from '../../db/RDB';
import { POKE_TABLE } from '../../db/PokeTable';
import relationalStore from '@ohos.data.relationalStore';
import { generateBucket, Pokemon } from '../../model/Pokemon';
import { PokemonResponse } from '../../model/PokemonResponse';
import ArrayList from '@ohos.util.ArrayList';
import { ViewState } from '../../common/State';
import { PokeInfo, PokemonInfoResponse } from '../../model/PokemonInfoResponse';
import { PokeListState } from './PokeListState';
import { PokeRepo } from '../../db/PokeRepo';
import { BusinessError } from '../../common/AsyncCallback';
import { ViewModel } from '../../common/ViewModel';

export class PokeListViewModel extends ViewModel {

  LOG_TAG: string = "PokeListViewModel-"

  pokeRepo = new PokeRepo();

  getPokemons() {
    this.setLoading()
    this.backgroundTask(this.getPokemonsTask())
  }

  updatePoke(json: string, poke: Pokemon) {
    this.backgroundTask(this.updatePokeTask(json, poke))
  }

  getPokeInfo(poke: Pokemon) {
    const callback = async (err: BusinessError<Error>, json: string ) => {
      if (json != null) {
        return new Promise((resolve, reject) => {
          this.updatePoke(json, poke)
        })
      } else {

      }
    }
    this.pokeRepo.getPokeInfo(poke, callback)
  }

  private setContent(pokemons: ArrayList<Pokemon>) {
    console.info(this.LOG_TAG + "setContent");
    try {
      let counter = 0
      pokemons.forEach((poke) => {
        poke.id = counter
        counter++
      }
      )
      let setResult = false
      const state: PokeListState = { pokemonsList: pokemons }
      setResult = this.storage.set<ViewState<PokeListState>>("pokeListState", ViewState.content(state));
      console.log("setResult-" + setResult);
    } catch (e) {
      this.setError(e)
      console.error(e)
    }
  }

  private async updateContent(pokemon: Pokemon) {
    console.info(this.LOG_TAG + "updateContent");
    try {
      let setResult = false
      setResult = this.storage.set<Pokemon>("pokeUpdate", pokemon);
      console.log("setResult-" + setResult);
    } catch (e) {
      this.setError(e)
      console.error(e)
    }
  }

  private setError(e) {
    try {
      const setResult = this.storage.set<ViewState<ArrayList<Pokemon>>>("pokeListState", ViewState.error(e));
      console.log("setResult-" + setResult);
    } catch (e) {
      console.error(e)
    }
  }

  private setLoading() {
    try {
      const setResult = this.storage.set<ViewState<ArrayList<Pokemon>>>("pokeListState", ViewState.loading);
      console.log("setResult-" + setResult);
    } catch (e) {
      console.error(e)
    }
  }

  private async getPokemonsTask() {
    try {
      if (await this.pokeRepo.count() != 0) {
        console.info(this.LOG_TAG + "load from db")
        const pokeList = await this.pokeRepo.getAll()
        this.setContent(pokeList)
      } else {
        console.info(this.LOG_TAG + "load from server")
        this.callPokemonsFromServer()
      }
    } catch (e) {
      this.setError(e)
      console.error(this.LOG_TAG + `error get: ${e}`);
    }
  }

  private async updatePokeTask(json: string, poke: Pokemon) {
    const pokeInfo: PokemonInfoResponse = JSON.parse(json)
    try {
      poke.picUrl = PokeInfo.getFrontSprite(pokeInfo.sprites)
    } catch (e) {
      console.error(e)
    }
    await this.pokeRepo.updateData(poke)
    this.updateContent(poke)
  }

  private callPokemonsFromServer() {
    const callback = async (err: BusinessError<Error>, json: string ) => {
      if (json != null) {
        const pokemonResponse: PokemonResponse = JSON.parse(json)
        return new Promise((resolve, reject) => {
          this.savePokemonsToDb(pokemonResponse.results)
        })
      } else {
        this.setError(err)
      }
    }
    this.pokeRepo.callPokemonsFromServer(callback)
  }

  async savePokemonsToDb(pokemons: Pokemon[]) {
    try {
      await this.pokeRepo.insertAll(pokemons)
      this.setContent(await this.pokeRepo.getAll())
    } catch (e) {
      this.setError(e)
      console.error(e)
    }
  }

}