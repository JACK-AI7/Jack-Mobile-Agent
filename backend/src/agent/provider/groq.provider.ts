import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Groq from 'groq-sdk';
import { AIProvider } from './ai.router.js';

const GROQ_FAST_MODEL = 'llama3-8b-8192';
const GROQ_TIMEOUT_MS = 30_000;

@Injectable()
export class GroqProvider implements AIProvider {
  readonly name = 'GROQ';
  readonly trainingUse = false;

  private readonly client: Groq;
  private readonly logger = new Logger(GroqProvider.name);

  constructor(apiKey: string) {
    this.client = new Groq({
      apiKey,
      timeout: GROQ_TIMEOUT_MS,
    });
  }

  async generate(prompt: string, _options?: any): Promise<string> {
    this.logger.log(`Generating response via ${this.name} [model=${GROQ_FAST_MODEL}]`);
    const completion = await this.client.chat.completions.create({
      model: GROQ_FAST_MODEL,
      messages: [{ role: 'user', content: prompt }],
    });
    return completion.choices[0]?.message?.content ?? '';
  }

  async generateStructured(prompt: string, schema: any, _options?: any): Promise<any> {
    this.logger.log(`Generating structured response via ${this.name} [model=${GROQ_FAST_MODEL}]`);
    const raw = await this.generate(
      `${prompt}\n\nRespond ONLY with valid JSON that conforms to the following schema: ${JSON.stringify(schema)}`,
    );

    // Strip markdown code fences if present
    const cleaned = raw.replace(/^```(?:json)?\n?/m, '').replace(/\n?```$/m, '').trim();
    return JSON.parse(cleaned);
  }
}
