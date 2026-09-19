import { Injectable, Logger } from '@nestjs/common';
import { AIProviderRouter } from '../provider/ai.router.js';

export interface AgentDefinition {
  name: string;
  description: string;
  goal: string;
  trigger: string;
  schedule?: string;
  tools: string[];
  permissions: string[];
}

@Injectable()
export class AgentGenerationService {
  private readonly logger = new Logger(AgentGenerationService.name);

  constructor(private aiRouter: AIProviderRouter) {}

  async generateAgentFromRequest(naturalLanguage: string): Promise<AgentDefinition> {
    this.logger.log(`Generating automatic agent from request: ${naturalLanguage}`);
    
    // Create the schema to enforce with structured output
    const schema = {
      type: "object",
      properties: {
        name: { type: "string" },
        description: { type: "string" },
        goal: { type: "string" },
        trigger: { type: "string" },
        schedule: { type: "string" },
        tools: { type: "array", items: { type: "string" } },
        permissions: { type: "array", items: { type: "string" } }
      },
      required: ["name", "description", "goal", "trigger", "tools", "permissions"]
    };

    // This will route to the provider and throw ProviderUnavailableError if unconfigured.
    const agentDef = await this.aiRouter.generateStructured(
      `Generate a strict JSON agent definition for this request: ${naturalLanguage}`,
      schema,
      'PRIVATE'
    );

    return agentDef as AgentDefinition;
  }
}
