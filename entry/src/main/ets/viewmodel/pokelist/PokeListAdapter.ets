import ArrayList from '@ohos.util.ArrayList';
import { BasicDataSource } from '../../common/BasicDataSource';
import { Pokemon } from '../../model/Pokemon';

export class PokeListAdapter extends BasicDataSource<Pokemon>  {
  private dataArray: Pokemon[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): Pokemon {
    return this.dataArray[index];
  }

  public updateRangeData(data: ArrayList<Pokemon>): void {
    data.forEach((poke) => {
      this.updateData(poke.id, poke)
    })
  }

  public updateData(index: number, data: Pokemon): void {
    console.debug("update-" + data.name)
    this.dataArray.splice(index, 1, data)
    this.notifyDataChange(index);
  }

  public addAllData(array: ArrayList<Pokemon>): void {
    this.dataArray.splice(0, this.dataArray.length)
    array.forEach((data) => {
      this.dataArray.push(data);
    })
    this.notifyDataReload()
  }
}
