import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { configurerApp } from './app.setup.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  configurerApp(app);
  // 0.0.0.0 et non 127.0.0.1 : le téléphone, relié au Raspberry Pi par le hotspot, doit pouvoir joindre ce serveur.
  await app.listen(process.env.PORT ?? 3000, '0.0.0.0');
}
await bootstrap();
