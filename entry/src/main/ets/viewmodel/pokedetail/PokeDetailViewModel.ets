import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import relationalStore from '@ohos.data.relationalStore';
import { store } from '../../db/RDB';
import { POKE_TABLE } from '../../db/PokeTable';
import { PokeDetailState } from './PokeDetailState';
import { ViewState } from '../../common/State';
import { PokeRepo } from '../../db/PokeRepo';

export class PokeDetailViewModel {
  constructor(storage: LocalStorage) {
    this.storage = storage
  }
  LOG_TAG: string = "PokeDetailViewModel-"

  storage: LocalStorage
  id: number = 1; // ID of the suspension delay request.
  delayTime: number = 5000; // Remaining duration for the suspension delay request.

  pokeRepo = new PokeRepo();

  private setError(e) {
    try {
      const setResult = this.storage.set<ViewState<PokeDetailState>>("pokeDetailState", ViewState.error(e));
      console.log("setResult-" + setResult);
    } catch (e) {
      console.error(e)
    }
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

  async getPokemon(name: string) {
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
      const poke = await this.pokeRepo.getByName(name)
      const setResult = this.storage.set<ViewState<PokeDetailState>>("pokeDetailState", ViewState.content({pokemon: poke}));
      console.log("setResult-" + setResult);
    } catch (e) {
      this.setError(e)
      console.error(this.LOG_TAG + `error get: ${e}`);
    }

    console.log("Waiting done.");
    //router.replaceUrl({ url: RouteConstants.POKE_LIST })

    // After the time-consuming task is executed, call the API to cancel the transient task.
    this.cancelSuspendDelay();
  }

}