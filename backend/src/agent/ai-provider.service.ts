import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AIProviderRouter } from './provider/ai.router.js';

export type AIModelTier = 'FAST' | 'REASONING' | 'VISION';

@Injectable()
export class AIProviderService {
  constructor(
    private configService: ConfigService,
    private aiRouter: AIProviderRouter
  ) {}

  async generate(prompt: string, tier: AIModelTier = 'FAST'): Promise<string> {
    return this.aiRouter.route(prompt, 'PRIVATE');
  }

  async generateStructured(prompt: string, schema: any): Promise<any> {
    return this.aiRouter.generateStructured(prompt, schema, 'PRIVATE');
  }
}
