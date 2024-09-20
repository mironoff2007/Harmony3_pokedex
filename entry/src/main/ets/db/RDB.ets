import relationalStore from '@ohos.data.relationalStore'
import UIAbility from '@ohos.app.ability.UIAbility'

export let store: relationalStore.RdbStore;

let config: relationalStore.StoreConfig = {
  name: 'pokemon.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

export function loadRdbStore(ability: UIAbility): Promise<relationalStore.RdbStore> {
  return new Promise((resolve, reject) => {
    relationalStore.getRdbStore(ability.context, config, (err, rdbStore) => {
      store = rdbStore;
      if (err) {
        console.error(`Get RdbStore failed, err: ${err}`);
        return;
      }
      console.info(`Get RdbStore successfully.`);
    })
  })
}