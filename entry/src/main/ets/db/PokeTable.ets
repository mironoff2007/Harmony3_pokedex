
export const POKE_TABLE = {
  tableName: 'pokeTable',
  sqlCreate: 'CREATE TABLE IF NOT EXISTS pokeTable(' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'name TEXT, ' +
  'picUrl TEXT' +
  ')',
  columns: ['id', 'name', 'picUrl']
};

