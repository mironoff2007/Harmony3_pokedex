import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import { SplashConstants } from '../viewmodel/SplashConstants';
import {store} from '../db/RDB'
import relationalStore from '@ohos.data.relationalStore';

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
    await this.insert()
    await this.get()
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
      let u8 = new Uint8Array([1, 2, 3]);
      const valueBucket = { "name": "Tom", "age": 18, "salary": 100.5, "blobType": u8 };
      let promise = store.insert("test", valueBucket);
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

  async get() {
    try {
      let predicates = new relationalStore.RdbPredicates("test");
      let promisequery = store.query(predicates);
      await promisequery.then((resultSet) => {
        resultSet.goToFirstRow();
        const id = resultSet.getLong(resultSet.getColumnIndex("id"));
        const name = resultSet.getString(resultSet.getColumnIndex("name"));
        const age = resultSet.getLong(resultSet.getColumnIndex("age"));
        const salary = resultSet.getDouble(resultSet.getColumnIndex("salary"));
        const blobType = resultSet.getBlob(resultSet.getColumnIndex("blobType"));
        resultSet.close();
      })
    }
    catch (err) {
      console.error(`err: ${err}`);
    }
  }

  async sleep(msec: number): Promise<number> {
    return new Promise<number>(resolve => setTimeout(resolve, msec));
  }
}