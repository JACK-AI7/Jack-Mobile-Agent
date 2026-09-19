import { Injectable, Logger } from '@nestjs/common';
import { AIProviderService } from '../ai-provider.service.js';
import { ToolRegistryService } from '../registry/tool-registry.service.js';
import { DeviceCapabilityRegistry } from '../../device/capability.registry.js';
import { PrivacyPolicyEngine } from '../../privacy/privacy.service.js';
import { RiskLevel } from '../registry/tool-registry.service.js';

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
    
    const { safeText, allowed } = this.privacyEngine.canSendToProvider(userRequest, false);
    if (!allowed) throw new Error('Request blocked by Privacy Policy Engine.');

    const tools = this.toolRegistry.getAllTools().slice(0, 5).map(t => t.name);
    const toolList = tools.length > 0 ? tools.join(', ') : 'none';

    const prompt = `You are JACK AI Agent Planner. Task: "${safeText.slice(0, 300)}". Tools: [${toolList}].
Return ONLY valid JSON: {"intent":"string","steps":[{"id":"s1","description":"string","tool":null,"requiresApproval":false,"dependencies":[]}],"estimatedRisk":"LOW"}`;
    
    let rawText: string;
    try {
      rawText = await this.aiProvider.generate(prompt);
    } catch (err: any) {
      throw new Error('AI provider failed during planning: ' + err.message);
    }

    // Extract JSON from the response
    const jsonMatch = rawText.match(/{[\s\S]*}/);
    if (!jsonMatch) {
      // Fallback: create a simple direct response plan
      return {
        success: true,
        plan: {
          intent: safeText.slice(0, 100),
          steps: [{ id: 's1', description: 'Process request directly', tool: null, requiresApproval: false, dependencies: [] }],
          estimatedRisk: RiskLevel.LOW,
        }
      };
    }

    try {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        success: true,
        plan: {
          intent: parsed.intent || safeText.slice(0, 100),
          steps: (parsed.steps || []).map((s: any, i: number) => ({
            id: s.id || `s${i+1}`,
            description: s.description || 'Step',
            tool: s.tool || null,
            requiresApproval: s.requiresApproval === true,
            dependencies: Array.isArray(s.dependencies) ? s.dependencies : [],
          })),
          estimatedRisk: (parsed.estimatedRisk as RiskLevel) || RiskLevel.LOW,
        }
      };
    } catch {
      return {
        success: true,
        plan: {
          intent: safeText.slice(0, 100),
          steps: [{ id: 's1', description: 'Direct response', tool: null, requiresApproval: false, dependencies: [] }],
          estimatedRisk: RiskLevel.LOW,
        }
      };
    }
  }
}
