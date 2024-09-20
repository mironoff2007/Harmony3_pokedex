export class Pokemon {
  constructor(id: number,
              name: string,
              picUrl: string
  ) {
    this.id = id
    this.name = name
    this.picUrl = picUrl
  }

  id: number;
  name: string;
  picUrl: string;
}