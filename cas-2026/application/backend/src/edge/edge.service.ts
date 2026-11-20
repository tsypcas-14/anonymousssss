import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { edgeConfig } from './edge.config.js';

/**
 * Pont vers l'API Flask « edge_ai » du Raspberry Pi (GET /etat, POST /commande).
 * Les réponses de Flask sont relayées telles quelles ; seules les pannes réseau sont traduites :
 *  - Flask injoignable ou trop lent : 503 avec un message clair (le backend ne plante pas) ;
 *  - Flask répond une erreur (ex. 400 « réservoir vide ») : même code et même corps `{ "erreur": "..." }`.
 */
@Injectable()
export class EdgeService {
  /** Tout l'état du système (capteurs, décisions de l'IA, actionneurs, alertes…). */
  getEtat(): Promise<unknown> {
    return this.appeler('GET', '/etat');
  }

  /** Envoie une commande manuelle (`kind` : water, fan, stop_watering, set_mode, unlock_pump). */
  envoyerCommande(corps: unknown): Promise<unknown> {
    return this.appeler('POST', '/commande', corps);
  }

  private async appeler(methode: 'GET' | 'POST', chemin: string, corps?: unknown): Promise<unknown> {
    const { url, timeoutMs } = edgeConfig();

    const options: RequestInit = { method: methode, signal: AbortSignal.timeout(timeoutMs) };
    if (corps !== undefined) {
      options.headers = { 'content-type': 'application/json' };
      options.body = JSON.stringify(corps);
    }

    let reponse: Response;
    try {
      reponse = await fetch(`${url}${chemin}`, options);
    } catch (erreur) {
      const delai = erreur instanceof Error && (erreur.name === 'TimeoutError' || erreur.name === 'AbortError');
      throw new HttpException(
        {
          erreur: delai
            ? `L'API edge ne répond pas : délai de ${timeoutMs / 1000} s dépassé.`
            : `L'API edge locale est injoignable (${url}). Le service edge est-il démarré ?`,
        },
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }

    const texte = await reponse.text();
    let json: unknown = null;
    if (texte.length > 0) {
      try {
        json = JSON.parse(texte);
      } catch {
        throw new HttpException({ erreur: "Réponse illisible de l'API edge." }, HttpStatus.BAD_GATEWAY);
      }
    }

    if (!reponse.ok) {
      // Refus de Flask : on garde son code et son message tels quels.
      const corpsErreur = json !== null && typeof json === 'object' ? json : { erreur: `L'API edge a répondu ${reponse.status}.` };
      throw new HttpException(corpsErreur, reponse.status);
    }
    return json;
  }
}
