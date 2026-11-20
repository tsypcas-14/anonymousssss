/** Réglages du pont vers l'API Flask « edge_ai » (lus à chaque appel : on peut les changer sans recompiler). */
export interface EdgeConfig {
  /** Adresse de l'API Flask locale, sans « / » final. Variable d'environnement : EDGE_API_URL. */
  url: string;
  /** Délai maximal d'un appel à Flask, en millisecondes (les capteurs DHT et ultrason peuvent être lents). */
  timeoutMs: number;
}

export const EDGE_URL_PAR_DEFAUT = 'http://127.0.0.1:5000';
export const EDGE_TIMEOUT_PAR_DEFAUT_MS = 5000;

export function edgeConfig(env: NodeJS.ProcessEnv = process.env): EdgeConfig {
  const timeout = Number(env.EDGE_TIMEOUT_MS);
  return {
    url: (env.EDGE_API_URL?.trim() || EDGE_URL_PAR_DEFAUT).replace(/\/+$/, ''),
    timeoutMs: Number.isFinite(timeout) && timeout > 0 ? timeout : EDGE_TIMEOUT_PAR_DEFAUT_MS,
  };
}
