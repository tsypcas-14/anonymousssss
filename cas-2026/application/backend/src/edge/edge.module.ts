import { Module } from '@nestjs/common';
import { EdgeController } from './edge.controller.js';
import { EdgeService } from './edge.service.js';

/** Pont entre l'application Flutter (réseau du hotspot) et l'API Flask « edge_ai » (127.0.0.1:5000). */
@Module({
  controllers: [EdgeController],
  providers: [EdgeService],
  exports: [EdgeService],
})
export class EdgeModule {}
