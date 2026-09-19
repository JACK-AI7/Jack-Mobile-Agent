import { Injectable, Logger } from '@nestjs/common';
import { AIProviderService } from '../ai-provider.service.js';
import { ToolRegistryService } from '../registry/tool-registry.service.js';
import { DeviceCapabilityRegistry } from '../../device/capability.registry.js';
import { PrivacyPolicyEngine } from '../../privacy/privacy.service.js';
import { AgentPlanSchema } from '../schemas/planner.schema.js';

@Injectable()
export class AgentPlannerService {
  private readonly logger = new Logger(AgentPlannerService.name);

  constructor(
    private aiProvider: AIProviderService,
    private toolRegistry: ToolRegistryService,
    private capabilityRegistry: DeviceCapabilityRegistry,
    private privacyEngine: PrivacyPolicyEngine
  ) {}

  async createExecutablePlan(userRequest: string) {
    this.logger.log(`Constructing plan for: ${userRequest}`);
    
    // 1. Privacy Check (Redact OTPs, etc.)
    const { safeText, allowed } = this.privacyEngine.canSendToProvider(userRequest, false);
    if (!allowed) {
      throw new Error("Request blocked by Privacy Policy Engine.");
    }

    // 2. Capability Discovery
    // The AI reads the available tools and maps the intent to tools.
    const tools = this.toolRegistry.getAllTools().map(t => t.name).join(', ');
    
    // 3. AI Plan Generation (using safe text)
    const prompt = `You are JACK Planner. Create a strict sequence of actions to solve this: "${safeText}". Available tools: [${tools}]`;
    
    // Actually call the structured output function instead of mocking it.
    // If provider is missing, it will throw ProviderUnavailableError.
    const structuredOutput = await this.aiProvider.generateStructured(prompt, AgentPlanSchema);

    // Zod validation (the AI Provider might already do this depending on the implementation)
    const plan = AgentPlanSchema.parse(structuredOutput);

    return {
      success: true,
      plan
    };
  }
}
