import { Module } from '@nestjs/common';
import { DatabaseModule } from './database/database.module.js';
import { SensorsModule } from './sensors/sensors.module.js';
import { ActuatorsModule } from './actuators/actuators.module.js';
import { NotificationsModule } from './notifications/notifications.module.js';
import { HistoryModule } from './history/history.module.js';
import { SettingsModule } from './settings/settings.module.js';
import { EdgeModule } from './edge/edge.module.js';
import { HealthController } from './health/health.controller.js';

@Module({
  imports: [DatabaseModule, SensorsModule, ActuatorsModule, NotificationsModule, HistoryModule, SettingsModule, EdgeModule],
  controllers: [HealthController],
})
export class AppModule {}
