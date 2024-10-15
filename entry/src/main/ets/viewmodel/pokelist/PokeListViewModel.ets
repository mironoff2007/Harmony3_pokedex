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
  id: number = 1; // ID of the suspension delay request.
  delayTime: number = 5000; // Remaining duration for the suspension delay request.

  pokeRepo = new PokeRepo();

  async getPokemons() {
    this.setLoading()
    // Before executing a time-consuming task, call the API to request a transient task to delay the suspension.
    this.requestSuspendDelay();

    // If required, obtain the available time quota through the getRemainingDelayTime() API.
    await this.getRemainingDelayTime();

    if (this.delayTime < 0) { // If the time is less than a certain value, cancel the time-consuming task.
      // Handle the scenario where the time quota is insufficient.
      this.cancelSuspendDelay();
      return;
    }

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

    // After the time-consuming task is executed, call the API to cancel the transient task.
    this.cancelSuspendDelay();
  }

  async updatePoke(json: string, poke: Pokemon) {
    // Before executing a time-consuming task, call the API to request a transient task to delay the suspension.
    this.requestSuspendDelay();

    // If required, obtain the available time quota through the getRemainingDelayTime() API.
    await this.getRemainingDelayTime();

    if (this.delayTime < 0) { // If the time is less than a certain value, cancel the time-consuming task.
      // Handle the scenario where the time quota is insufficient.
      this.cancelSuspendDelay();
      return;
    }
    const pokeInfo: PokemonInfoResponse = JSON.parse(json)
    try {
      poke.picUrl = PokeInfo.getFrontSprite(pokeInfo.sprites)
    } catch (e) {
      console.error(e)
    }
    await this.pokeRepo.updateData(poke)
    this.updateContent(poke)

    this.cancelSuspendDelay();
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

  // Request a suspension delay.
  private requestSuspendDelay() {
    const myReason = 'test requestSuspendDelay'; // Reason for the suspension delay request.

    try {
      const delayInfo = backgroundTaskManager.requestSuspendDelay(myReason, () => {
        // The callback is invoked to notify the application that the suspension delay request is about to time out. The application needs to perform some cleanup and annotation operations and cancels the transient task.
        console.info("[backgroundTaskManager] Request suspension delay will time out.");
        backgroundTaskManager.cancelSuspendDelay(this.id);
      })
      this.id = delayInfo.requestId;
      this.delayTime = delayInfo.actualDelayTime;

      console.info("[backgroundTaskManager] The requestId is: " + this.id);
      console.info("[backgroundTaskManager]The actualDelayTime is: " + this.delayTime);
    } catch (error) {
      console.error(`[backgroundTaskManager] requestSuspendDelay failed. code is ${error.code} message is ${error.message}`);
    }
  }

  // Obtain the remaining duration before the application is suspended.
  private async getRemainingDelayTime() {
    try {
      await backgroundTaskManager.getRemainingDelayTime(this.id)
        .then(res => {
          console.log('[backgroundTaskManager] promise => Operation getRemainingDelayTime succeeded. Data: ' +
          JSON.stringify(res));
        }
        )
    } catch (error) {
      console.error(`[backgroundTaskManager] promise => Operation getRemainingDelayTime failed. code is ${error.code} message is ${error.message}`);
    }
  }

  // Cancel the suspension delay.
  private cancelSuspendDelay() {
    backgroundTaskManager.cancelSuspendDelay(this.id);
  }

  async savePokemonsToDb(pokemons: Pokemon[]) {
    // Before executing a time-consuming task, call the API to request a transient task to delay the suspension.
    this.requestSuspendDelay();

    // If required, obtain the available time quota through the getRemainingDelayTime() API.
    await this.getRemainingDelayTime();

    if (this.delayTime < 0) { // If the time is less than a certain value, cancel the time-consuming task.
      // Handle the scenario where the time quota is insufficient.
      this.cancelSuspendDelay();
      return;
    }

    // Execute the time-consuming task.
    try {
      await this.pokeRepo.insertAll(pokemons)
      this.setContent(await this.pokeRepo.getAll())
    } catch (e) {
      this.setError(e)
      console.error(e)
    }

    // After the time-consuming task is executed, call the API to cancel the transient task.
    this.cancelSuspendDelay();
  }

}