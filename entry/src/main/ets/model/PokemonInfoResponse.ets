export type PokemonInfoResponse = {
  sprites: Sprites;
}

export type Sprites = {
  front_default: string;
}

export const PokeInfo = {
  getFrontSprite: (sprites: Sprites) => sprites.front_default
}
