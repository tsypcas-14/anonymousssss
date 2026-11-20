import { createServer, type IncomingMessage, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { AppModule } from './../src/app.module.js';
import { configurerApp } from './../src/app.setup.js';

process.env.SMARTFARM_DB = ':memory:';

/** Un extrait réel de la réponse de GET /etat (le backend doit la relayer sans la modifier). */
const ETAT = {
  actuators: { buzzer: false, fan: true, pump: false },
  alarms: { fire: false, missing: false, pump_locked: false, tank_low: true },
  alerts: [{ detail: 'Fill it: the pump is forbidden until then.', id: 'tank', level: 'watch', since: '2026-11-18T16:37:34', title: 'The tank is empty' }],
  command: null,
  modes: { fan: { mode: 'auto' }, irrigation: { mode: 'auto' } },
  sensors: { air_temp: 26.4, soil_pct: 52.3, flame: false },
  simulated: false,
};

/** Faux « edge_ai » : mêmes routes que l'API Flask, avec ses refus. */
function lireCorps(req: IncomingMessage): Promise<string> {
  return new Promise((resolve) => {
    let texte = '';
    req.on('data', (morceau) => (texte += morceau));
    req.on('end', () => resolve(texte));
  });
}

describe('Pont edge (e2e)', () => {
  let flask: Server;
  let recu: unknown[];
  let delaiMs: number;
  let app: INestApplication<App>;

  beforeAll(async () => {
    recu = [];
    delaiMs = 0;
    flask = createServer(async (req, res) => {
      await new Promise((r) => setTimeout(r, delaiMs));
      res.setHeader('content-type', 'application/json');
      if (req.method === 'GET' && req.url === '/etat') {
        res.end(JSON.stringify(ETAT));
      } else if (req.method === 'POST' && req.url === '/commande') {
        const corps = JSON.parse(await lireCorps(req)) as { kind?: string; seconds?: number };
        recu.push(corps);
        if (corps.kind === 'water' && ![3, 5, 8].includes(corps.seconds ?? 0)) {
          res.statusCode = 400;
          res.end(JSON.stringify({ erreur: 'seconds must be 3, 5 or 8' }));
        } else if (corps.kind === 'water' && ETAT.alarms.tank_low) {
          res.statusCode = 400;
          res.end(JSON.stringify({ erreur: 'The tank is empty: watering is forbidden.' }));
        } else {
          res.end(JSON.stringify({ status: 'accepted', message: `${corps.kind} ok` }));
        }
      } else {
        res.statusCode = 404;
        res.end(JSON.stringify({ erreur: 'not found' }));
      }
    });
    await new Promise<void>((resolve) => flask.listen(0, '127.0.0.1', resolve));
    process.env.EDGE_API_URL = `http://127.0.0.1:${(flask.address() as AddressInfo).port}`;
    process.env.EDGE_TIMEOUT_MS = '300';

    const moduleFixture = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleFixture.createNestApplication();
    configurerApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
    await new Promise((resolve) => flask.close(resolve));
  });

  beforeEach(() => {
    recu = [];
    delaiMs = 0;
  });

  it('GET /edge/etat relaie le JSON de Flask sans le modifier', async () => {
    const reponse = await request(app.getHttpServer()).get('/edge/etat').expect(200);
    expect(reponse.body).toEqual(ETAT);
  });

  it('POST /edge/commande relaie le corps vers Flask et renvoie sa réponse', async () => {
    const reponse = await request(app.getHttpServer()).post('/edge/commande').send({ kind: 'fan', on: true, who: 'app' }).expect(200);
    expect(reponse.body).toEqual({ status: 'accepted', message: 'fan ok' });
    expect(recu).toEqual([{ kind: 'fan', on: true, who: 'app' }]);
  });

  it("POST /edge/commande renvoie l'erreur 400 de Flask avec son message", async () => {
    const reponse = await request(app.getHttpServer()).post('/edge/commande').send({ kind: 'water', seconds: 7, who: 'app' }).expect(400);
    expect(reponse.body).toEqual({ erreur: 'seconds must be 3, 5 or 8' });
    const reservoir = await request(app.getHttpServer()).post('/edge/commande').send({ kind: 'water', seconds: 5, who: 'app' }).expect(400);
    expect(reservoir.body).toEqual({ erreur: 'The tank is empty: watering is forbidden.' });
  });

  it('refuse un corps qui n\'est pas un objet JSON (400) sans appeler Flask', async () => {
    const reponse = await request(app.getHttpServer()).post('/edge/commande').send([1, 2]).expect(400);
    expect(reponse.body.erreur).toContain("champ 'kind'");
    expect(recu).toEqual([]);
  });

  it('renvoie 503 avec un message clair quand Flask est trop lent', async () => {
    delaiMs = 800; // plus que EDGE_TIMEOUT_MS (300 ms)
    const reponse = await request(app.getHttpServer()).get('/edge/etat').expect(503);
    expect(reponse.body.erreur).toContain('ne répond pas');
  });

  it("renvoie 503 avec un message clair quand Flask n'est pas démarré", async () => {
    const ancienne = process.env.EDGE_API_URL;
    process.env.EDGE_API_URL = 'http://127.0.0.1:1'; // rien n'écoute sur ce port
    try {
      const reponse = await request(app.getHttpServer()).get('/edge/etat').expect(503);
      expect(reponse.body.erreur).toContain('injoignable');
      const commande = await request(app.getHttpServer()).post('/edge/commande').send({ kind: 'stop_watering', who: 'app' }).expect(503);
      expect(commande.body.erreur).toContain('injoignable');
    } finally {
      process.env.EDGE_API_URL = ancienne;
    }
  });

  it('autorise les appels depuis un autre appareil (CORS)', async () => {
    const reponse = await request(app.getHttpServer()).get('/edge/etat').set('Origin', 'http://192.168.43.10:5173').expect(200);
    expect(reponse.headers['access-control-allow-origin']).toBeDefined();
    const preflight = await request(app.getHttpServer())
      .options('/edge/commande')
      .set('Origin', 'http://192.168.43.10:5173')
      .set('Access-Control-Request-Method', 'POST')
      .set('Access-Control-Request-Headers', 'content-type');
    expect(preflight.status).toBeLessThan(300);
    expect(preflight.headers['access-control-allow-methods']).toContain('POST');
  });

  it('/health répond toujours', async () => {
    await request(app.getHttpServer()).get('/health').expect(200).expect({ status: 'ok' });
  });
});
