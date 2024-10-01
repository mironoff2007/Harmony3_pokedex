export const POKE_TABLE = {
  tableName: 'pokeTable',
  sqlCreate: 'CREATE TABLE IF NOT EXISTS pokeTable(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, url TEXT, picUrl TEXT, time INTEGER)',
  columns: ['id', 'name', 'url', 'picUrl', 'time']
};

