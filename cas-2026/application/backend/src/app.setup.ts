import type { INestApplication } from '@nestjs/common';

/** Réglages communs au démarrage réel (main.ts) et aux tests : CORS, pour que l'application Flutter, sur un autre appareil, puisse appeler le backend. */
export function configurerApp(app: INestApplication): void {
  app.enableCors();
}
