import { Injectable, OnModuleDestroy } from '@nestjs/common';
import Database from 'better-sqlite3';
import { mkdirSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Ouvre la base SQLite locale et crée les tables au démarrage (schema.sql, idempotent).
 * Chemin : variable SMARTFARM_DB, sinon ./data/smartfarm.sqlite. ':memory:' pour les tests.
 */
@Injectable()
export class DatabaseService implements OnModuleDestroy {
  readonly db: Database.Database;

  constructor() {
    const path = process.env.SMARTFARM_DB ?? resolve('data', 'smartfarm.sqlite');
    if (path !== ':memory:') mkdirSync(dirname(path), { recursive: true });
    this.db = new Database(path);
    this.db.pragma('journal_mode = WAL'); // lectures et écriture simultanées, plus doux pour la carte SD
    this.db.exec(readFileSync(fileURLToPath(new URL('./schema.sql', import.meta.url)), 'utf8'));
  }

  onModuleDestroy() {
    this.db.close();
  }
}
