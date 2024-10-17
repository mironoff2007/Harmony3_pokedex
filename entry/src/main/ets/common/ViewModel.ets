
import backgroundTaskManager from '@ohos.backgroundTaskManager';

export abstract class ViewModel {
  constructor(storage: LocalStorage) {
    this.storage = storage
  }
  storage: LocalStorage

  delayTime: number = 5000; // Remaining duration for the suspension delay request.

  // Request a suspension delay.
  private requestSuspendDelay(): number {
    const myReason = 'requestSuspendDelay'; // Reason for the suspension delay request.
    let id
    try {
      const delayInfo = backgroundTaskManager.requestSuspendDelay(myReason, () => {
        // The callback is invoked to notify the application that the suspension delay request is about to time out. The application needs to perform some cleanup and annotation operations and cancels the transient task.
        console.info("[backgroundTaskManager] Request suspension delay will time out.");
        backgroundTaskManager.cancelSuspendDelay(id);
      })
      id = delayInfo.requestId;
      this.delayTime = delayInfo.actualDelayTime;
      console.info("[backgroundTaskManager] The requestId is: " + id);
      console.info("[backgroundTaskManager]The actualDelayTime is: " + this.delayTime);
    } catch (error) {
      console.error(`[backgroundTaskManager] requestSuspendDelay failed. code is ${error.code} message is ${error.message}`);
    }
    return id
  }

  // Obtain the remaining duration before the application is suspended.
  private async getRemainingDelayTime(id: number) {
    try {
      await backgroundTaskManager.getRemainingDelayTime(id)
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
  private cancelSuspendDelay(id: number) {
    backgroundTaskManager.cancelSuspendDelay(id);
  }

  backgroundTask(task: Promise<void> ) {
    return new Promise(async (resolve, reject) => {
      // Before executing a time-consuming task, call the API to request a transient task to delay the suspension.
      const id = this.requestSuspendDelay();

      // If required, obtain the available time quota through the getRemainingDelayTime() API.
      await this.getRemainingDelayTime(id);

      if (this.delayTime < 0) { // If the time is less than a certain value, cancel the time-consuming task.
        // Handle the scenario where the time quota is insufficient.
        this.cancelSuspendDelay(id);
        return;
      }

      // Execute the time-consuming task.
      await task

      // After the time-consuming task is executed, call the API to cancel the transient task.
      this.cancelSuspendDelay(id);
    })
  }

}