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

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async generate(prompt: string): Promise<string> {
    try {
      const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + this.apiKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: 'llama-3.1-8b-instant',
          messages: [{ role: 'user', content: prompt }],
          max_tokens: 2048,
          temperature: 0.7,
        })
      });
      if (!response.ok) {
        const text = await response.text();
        throw new Error('Groq API Error: ' + response.status + ' ' + text);
      }
      const data = await response.json();
      return data.choices[0]?.message?.content || '';
    } catch (err: any) {
      throw new Error('Groq Fetch Error (generate): ' + err.message);
    }
  }

  async generateStructured(prompt: string, schema: any): Promise<any> {
    const structuredPrompt = `${prompt}\n\nRespond ONLY with valid JSON matching this schema: ${JSON.stringify(schema, null, 2)}\nDo not include any explanation, only the JSON object.`;
    try {
      const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + this.apiKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: 'llama-3.1-8b-instant',
          messages: [{ role: 'user', content: structuredPrompt }],
          max_tokens: 4096,
          temperature: 0.3,
          response_format: { type: 'json_object' }
        })
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
      throw new Error('Groq Fetch Error (generateStructured): ' + err.message);
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
