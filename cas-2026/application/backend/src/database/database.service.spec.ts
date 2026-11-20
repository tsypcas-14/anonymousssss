import { DatabaseService } from './database.service.js';

describe('DatabaseService', () => {
  let service: DatabaseService;

  beforeEach(() => {
    process.env.SMARTFARM_DB = ':memory:';
    service = new DatabaseService();
  });

  afterEach(() => service.onModuleDestroy());

  it('crée les 4 tables du schéma de départ', () => {
    const tables = service.db
      .prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
      .all()
      .map((r: any) => r.name);
    expect(tables).toEqual(['evenements', 'mesures', 'preferences', 'seuils']);
  });

  it('refuse un niveau d\'événement inconnu', () => {
    expect(() =>
      service.db.prepare("INSERT INTO evenements (type, texte, horodatage, niveau) VALUES ('x','y',1,'grave')").run(),
    ).toThrow();
  });

  it('accepte les trois niveaux du PDD', () => {
    const insert = service.db.prepare("INSERT INTO evenements (type, texte, horodatage, niveau) VALUES ('t','x',1,?)");
    for (const niveau of ['info', 'a_verifier', 'critique']) expect(() => insert.run(niveau)).not.toThrow();
  });
});
