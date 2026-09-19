import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Enable CORS securely configurable by env
  const corsOrigins = process.env.CORS_ORIGINS 
    ? process.env.CORS_ORIGINS.split(',') 
    : ['http://localhost:3000', 'http://localhost:8080'];
    
  app.enableCors({
    origin: corsOrigins,
    credentials: true,
  });

  const port = process.env.PORT || 3000;
  // Bind to 0.0.0.0 for Railway
  await app.listen(port, '0.0.0.0');
  
  logger.log(`Application successfully started on port ${port} (Mode: ${process.env.RUN_MODE || 'ALL'})`);
}
bootstrap();
