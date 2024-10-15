
export abstract class ViewModel {
  constructor(storage: LocalStorage) {
    this.storage = storage
  }
  storage: LocalStorage

}