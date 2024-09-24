import { POKE_TABLE } from '../db/PokeTable';
import relationalStore from '@ohos.data.relationalStore'

export class Pokemon  {
  id: number;
  name: string;
  url: string;
}

export function generateBucket(poke: Pokemon): relationalStore.ValuesBucket {
  const obj = {};
  POKE_TABLE.columns.forEach((item) => {
    if (item != 'id') {
      obj[item] = poke[item];
    }
  });
  return obj;
}
