
import ArrayList from '@ohos.util.ArrayList'
import { Pokemon } from '../../model/Pokemon'

export const PokeListDiffUtil = {

  getToUpdate: (current: ArrayList<Pokemon>, newPokeArray: ArrayList<Pokemon>): ArrayList<Pokemon> => {
    let updateArray = new ArrayList<Pokemon>()
    if (current.length == 0) {
      updateArray = newPokeArray
    } else {
      current.forEach((poke) => {
        newPokeArray.forEach((pokeNew) => {
          if (poke.id == pokeNew.id) {
            if(pokeNew.time!= poke.time) {
              updateArray.add(pokeNew)
            }
          }
        }
        )
      }
      )
    }
    return updateArray
  }
}