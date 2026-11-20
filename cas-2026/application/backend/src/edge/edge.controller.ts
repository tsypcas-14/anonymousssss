import { Body, Controller, Get, HttpCode, HttpException, HttpStatus, Post } from '@nestjs/common';
import { EdgeService } from './edge.service.js';

/** Routes consommées par l'application Flutter, relayées vers l'API Flask locale. */
@Controller('edge')
export class EdgeController {
  constructor(private readonly edge: EdgeService) {}

  /** Relaie GET /etat de Flask, tel quel. */
  @Get('etat')
  etat(): Promise<unknown> {
    return this.edge.getEtat();
  }

  /** Relaie le corps vers POST /commande de Flask et renvoie sa réponse (erreurs 400 comprises). */
  @Post('commande')
  @HttpCode(HttpStatus.OK)
  commande(@Body() corps: unknown): Promise<unknown> {
    if (corps === null || typeof corps !== 'object' || Array.isArray(corps)) {
      throw new HttpException(
        { erreur: "Le corps doit être un objet JSON avec un champ 'kind' (water, fan, stop_watering, set_mode, unlock_pump)." },
        HttpStatus.BAD_REQUEST,
      );
    }
    return this.edge.envoyerCommande(corps);
  }
}
