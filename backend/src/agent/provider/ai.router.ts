import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ProviderUnavailableError } from '../../common/exceptions/provider-unavailable.error.js';

export interface AIProvider {
  name: string;
  trainingUse: boolean;
  generate(prompt: string, options?: any): Promise<string>;
  generateStructured(prompt: string, schema: any, options?: any): Promise<any>;
}

class GroqProvider implements AIProvider {
  name = 'GROQ';
  trainingUse = false;
  private readonly logger = new Logger('GroqProvider');
  private apiKey: string;
  private activeModel: string | null = null;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  /** Models known to work reliably within Groq context limits, in preference order. */
  private static readonly MODEL_ALLOWLIST = [
    'llama3-groq-8b-8192-tool-use-preview',
    'llama-3.1-8b-instant',
    'meta-llama/llama-4-scout-17b-16e-instruct',
    'compound-beta',
  ];

  private async getModel(): Promise<string> {
    if (this.activeModel) return this.activeModel;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 15000);
    try {
      const res = await fetch('https://api.groq.com/openai/v1/models', {
        headers: { 'Authorization': 'Bearer ' + this.apiKey },
        signal: controller.signal,
      });
      const data = await res.json();
      if (data && Array.isArray(data.data) && data.data.length > 0) {
        const available: string[] = data.data.map((m: any) => m.id as string);
        // Prefer models in the allowlist (first match wins)
        for (const preferred of GroqProvider.MODEL_ALLOWLIST) {
          if (available.includes(preferred)) {
            this.activeModel = preferred;
            this.logger.log(`Selected model from allowlist: ${preferred}`);
            return preferred;
          }
        }
        // None matched allowlist — fall back to first available
        this.activeModel = available[0];
        this.logger.warn(`No allowlisted model found; using first available: ${available[0]}`);
        return available[0];
      }
    } catch (e: any) {
      this.logger.warn(`getModel() fetch failed (${e.message}); using hardcoded fallback`);
    } finally {
      clearTimeout(timer);
    }
    // Absolute fallback — smallest known-safe model
    return 'llama-3.1-8b-instant';
  }

  async generate(prompt: string): Promise<string> {
    const model = await this.getModel();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 15000);
    try {
      const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + this.apiKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: model,
          messages: [{ role: 'user', content: prompt }],
          max_tokens: 2048,
          temperature: 0.7,
        }),
        signal: controller.signal,
      });
      if (!response.ok) {
        const text = await response.text();
        throw new Error('Groq API Error: ' + response.status + ' ' + text);
      }
      const data = await response.json();
      return data.choices[0]?.message?.content || '';
    } catch (err: any) {
      throw new Error(`Groq Fetch Error (generate) [model=${model}]: ` + err.message);
    } finally {
      clearTimeout(timer);
    }
  }

  async generateStructured(prompt: string, schema: any): Promise<any> {
    const model = await this.getModel();
    const structuredPrompt = `${prompt}\n\nRespond ONLY with valid JSON matching this schema: ${JSON.stringify(schema, null, 2)}\nDo not include any explanation, only the JSON object.`;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 15000);
    try {
      const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + this.apiKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: model,
          messages: [{ role: 'user', content: structuredPrompt }],
          max_tokens: 1024,
          temperature: 0.3,
          response_format: { type: 'json_object' }
        }),
        signal: controller.signal,
      });
      if (!response.ok) {
        const text = await response.text();
        throw new Error('Groq API Error: ' + response.status + ' ' + text);
      }
      const data = await response.json();
      const raw = data.choices[0]?.message?.content || '{}';
      
      const jsonMatch = raw.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('Groq did not return valid JSON');
      return JSON.parse(jsonMatch[0]);
    } catch (err: any) {
      throw new Error(`Groq Fetch Error (generateStructured) [model=${model}]: ` + err.message);
    } finally {
      clearTimeout(timer);
    }
  }
}

@Injectable()
export class AIProviderRouter {
  private readonly logger = new Logger(AIProviderRouter.name);
  private providers: Map<string, AIProvider> = new Map();

  constructor(private config: ConfigService) {
    this.registerConfiguredProviders();
  }

  private registerConfiguredProviders() {
    const groqKey = this.config.get<string>('GROQ_API_KEY');
    if (groqKey && groqKey.trim().length > 0) {
      this.providers.set('GROQ', new GroqProvider(groqKey));
      this.logger.log('Registered provider: GROQ (llama3-8b-8192)');
    } else {
      this.logger.warn('AI_PROVIDER_NOT_CONFIGURED: GROQ_API_KEY is missing');
    }

    const openaiKey = this.config.get<string>('OPENAI_API_KEY');
    if (openaiKey && openaiKey.trim().length > 0) {
      this.logger.log('OpenAI API key detected (provider client not yet implemented)');
    }

    const anthropicKey = this.config.get<string>('ANTHROPIC_API_KEY');
    if (anthropicKey && anthropicKey.trim().length > 0) {
      this.logger.log('Anthropic API key detected (provider client not yet implemented)');
    }
  }

  private getProvider(): AIProvider {
    // Priority order: configured AI_PROVIDER env var, then first available
    const preferred = this.config.get<string>('AI_PROVIDER');
    if (preferred && this.providers.has(preferred)) {
      return this.providers.get(preferred)!;
    }
    // Fall back to first registered provider
    const first = this.providers.values().next().value;
    if (first) return first;
    throw new ProviderUnavailableError('NONE — no AI providers configured with valid API keys');
  }

  async route(prompt: string, sensitivity: 'PUBLIC' | 'PRIVATE' | 'SENSITIVE'): Promise<string> {
    const provider = this.getProvider();

    if (sensitivity === 'SENSITIVE' && provider.trainingUse) {
      throw new Error('Cannot route SENSITIVE data to a provider that trains on user data.');
    }

    this.logger.log(`Routing to ${provider.name} (sensitivity: ${sensitivity})`);
    return provider.generate(prompt);
  }

  async generateStructured(prompt: string, schema: any, sensitivity: 'PUBLIC' | 'PRIVATE' | 'SENSITIVE'): Promise<any> {
    const provider = this.getProvider();

    if (sensitivity === 'SENSITIVE' && provider.trainingUse) {
      throw new Error('Cannot route SENSITIVE data to a provider that trains on user data.');
    }

    this.logger.log(`Routing structured request to ${provider.name} (sensitivity: ${sensitivity})`);
    return provider.generateStructured(prompt, schema);
  }
}
