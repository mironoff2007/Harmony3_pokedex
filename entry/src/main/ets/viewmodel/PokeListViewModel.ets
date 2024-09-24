import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import http from '@ohos.net.http';

import { SplashConstants } from '../viewmodel/SplashConstants';
import { store } from '../db/RDB';
import { POKE_TABLE } from '../db/PokeTable';
import relationalStore from '@ohos.data.relationalStore';
import { generateBucket, Pokemon } from '../model/Pokemon';
import { PokemonResponse } from '../model/PokemonResponse';

export class PokeListViewModel {
  constructor(storage: LocalStorage) {
    this.storage = storage
  }

  storage: LocalStorage
  id: number = 1; // ID of the suspension delay request.
  delayTime: number = 5000; // Remaining duration for the suspension delay request.

  async getPokemons() {
    // Before executing a time-consuming task, call the API to request a transient task to delay the suspension.
    this.requestSuspendDelay();

    // If required, obtain the available time quota through the getRemainingDelayTime() API.
    await this.getRemainingDelayTime();

    if (this.delayTime < 0) { // If the time is less than a certain value, cancel the time-consuming task.
      // Handle the scenario where the time quota is insufficient.
      this.cancelSuspendDelay();
      return;
    }

    if(await this.count() > 1000) {
      this.get()
    } else {
      this.callPokemonsFromServer()
    }
    // Execute the time-consuming task.


    // After the time-consuming task is executed, call the API to cancel the transient task.
    this.cancelSuspendDelay();
  }

  private callPokemonsFromServer() {
   // Each HttpRequest corresponds to an HttpRequestTask object and cannot be reused.
    let httpRequest = http.createHttp();

    // Subscribe to the HTTP response header, which is returned earlier than HttpRequest. You can subscribe to HTTP Response Header events based on service requirements.
    // on('headerReceive', AsyncCallback) will be replaced by on('headersReceive', Callback) in API version 8. 8+
    httpRequest.on('headersReceive', (header) => {
      console.info('header: ' + JSON.stringify(header));
    });

    let callback = async (err: Error, data: http.HttpResponse)  => {
      if (!err) {
        // data.result contains the HTTP response. Parse the response based on service requirements.
        console.info('Result:' + data.result);
        console.info('code:' + data.responseCode);
        // data.header contains the HTTP response header. Parse the content based on service requirements.
        console.info('header:' + JSON.stringify(data.header));
        console.info('cookies:' + data.cookies); // 8+
        const json: string = data.result as string
        const pokeArray: PokemonResponse = JSON.parse(json)
        await this.savePokemonsToDb(pokeArray.results)
        await this.get()
      } else {
        console.info('error:' + JSON.stringify(err));
        // Call the destroy() method to release resources after the call is complete.
        httpRequest.destroy();
      }
    }
    httpRequest.request(
      // Set the URL of the HTTP request. You need to define the URL. Set the parameters of the request in extraData.
      "https://pokeapi.co/api/v2/pokemon?limit=100000&offset=0",
      {
        method: http.RequestMethod.GET, // Optional. The default value is http.RequestMethod.GET.
        // You can add the header field based on service requirements.
        header: {
          'Content-Type': 'application/json'
        },
        // This field is used to transfer data when the POST request is used.
        extraData: {
          "data": "data to send",
        },
        connectTimeout: 60000, // Optional. The default value is 60000, in ms.
        readTimeout: 60000, // Optional. The default value is 60000, in ms.
      }, callback
    )
  }

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
      let backets: Array<relationalStore.ValuesBucket> = pokemons.map(poke => {
        return generateBucket(poke)
      })
      await this.insertAll(backets)
      this.get()
    } catch (e) {
      console.error(e)
    }

    // After the time-consuming task is executed, call the API to cancel the transient task.
    this.cancelSuspendDelay();
  }

  async insert() {
    // Use a transaction to insert data.
    try {
      store.beginTransaction();
      const poke: any = {id:1, name:"poke1", url:"pic1"}
      let promise = store.insert(POKE_TABLE.tableName,poke);
      await promise.then(() => {
        store.commit();
        store.sync()
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

  async insertAll(pokemons : relationalStore.ValuesBucket[]) {
    // Use a transaction to insert data.
    try {
      store.beginTransaction();
      let promise = store.batchInsert(POKE_TABLE.tableName, pokemons)
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

  async count(): Promise<number> {
    const q = 'SELECT COUNT(*) FROM ' + POKE_TABLE.tableName
    return await store.querySql(q, []).then((resultSet) => {
      resultSet.goToFirstRow();
      const count = resultSet.getLong(0);
      console.info("poke count-" + count)
      return count
    }
    )
  }

  async get(): Promise<Pokemon> {
    try {
      await this.count()
      const predicates = new relationalStore.RdbPredicates(POKE_TABLE.tableName);
      const promisequery = store.query(predicates, POKE_TABLE.columns);
      return await promisequery.then((resultSet) => {
        const rows = resultSet.rowCount
        resultSet.goToFirstRow();
        const id = resultSet.getLong(resultSet.getColumnIndex("id"));
        const name = resultSet.getString(resultSet.getColumnIndex("name"));
        const url = resultSet.getString(resultSet.getColumnIndex("url"));
        resultSet.close();
        return { id, name, url }
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