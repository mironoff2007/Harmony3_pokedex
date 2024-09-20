import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import { SplashConstants } from '../viewmodel/SplashConstants';
import {store} from '../db/RDB'
import relationalStore from '@ohos.data.relationalStore';
import { Pokemon } from '../model/Pokemon';
import { POKE_TABLE } from '../db/PokeTable';

export class SplashViewModel {
  constructor(storage: LocalStorage) {
    this.storage = storage
  }

  storage: LocalStorage
  id: number = 1; // ID of the suspension delay request.
  delayTime: number = 5000; // Remaining duration for the suspension delay request.

  // Request a suspension delay.
  private requestSuspendDelay() {
    let myReason = 'test requestSuspendDelay'; // Reason for the suspension delay request.

    try {
      let delayInfo = backgroundTaskManager.requestSuspendDelay(myReason, () => {
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

  async performLongRunningTask() {
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
    await store.executeSql(POKE_TABLE.sqlCreate).catch(err => {
      if (err) {
        console.error(`create table error: ${err}`);
      }
    });
    await this.insert()
    const poke = await this.get()
    await this.sleep(3000)
    try {
      let setResult = this.storage.set<boolean>(SplashConstants.SPLASH_END, true);
      console.log("setResult-" + setResult);
    } catch (e) {
      console.error(e)
    }

    console.log("Waiting done.");
    //router.replaceUrl({ url: RouteConstants.POKE_LIST })

    // After the time-consuming task is executed, call the API to cancel the transient task.
    this.cancelSuspendDelay();
  }

  async insert() {
    // Use a transaction to insert data.
    try {
      store.beginTransaction();
      const poke: any = new Pokemon(1, "poke1", "pic1")
      let promise = store.insert(POKE_TABLE.tableName, poke);
      await promise.then(() => {
        store.commit();
      })
    } catch (err) {
      if ((err instanceof Error)) {
        console.error(`Transaction failed, err: ${err.message}`);
      } else if (err instanceof String) {
        console.error(`Transaction failed, err: ${err}`);
      }
      console.error(`Transaction failed, err: ${err}`);
      store.rollBack();
    }
  }

  async get(): Promise<Pokemon> {
    try {
      let predicates = new relationalStore.RdbPredicates(POKE_TABLE.tableName);
      let promisequery = store.query(predicates);
      return await promisequery.then((resultSet) => {
        resultSet.goToFirstRow();
        const id = resultSet.getLong(resultSet.getColumnIndex("id"));
        const name = resultSet.getString(resultSet.getColumnIndex("name"));
        const picUrl = resultSet.getString(resultSet.getColumnIndex("picUrl"));
        resultSet.close();
        return new Pokemon(id, name, picUrl)
      })
    }
    catch (err) {
      console.error(`err: ${err}`);
      return null
    }
  }

  async sleep(msec: number): Promise<number> {
    return new Promise<number>(resolve => setTimeout(resolve, msec));
  }
}