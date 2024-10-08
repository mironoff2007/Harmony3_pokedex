import ArrayList from '@ohos.util.ArrayList'
import { Pokemon } from '../../model/Pokemon'

export type PokeListState = {
  lastPokemons: ArrayList<Pokemon>
  pokemonToUpdate: Pokemon
}