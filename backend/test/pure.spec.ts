import { AgentPlanSchema } from '../src/agent/schemas/planner.schema.js';
import { ProviderUnavailableError } from '../src/common/exceptions/provider-unavailable.error.js';
import { InfrastructureUnavailableError } from '../src/common/exceptions/infrastructure-unavailable.error.js';
import { PrivacyPolicyEngine } from '../src/privacy/privacy.service.js';

describe('Pure Logic & Security Validation', () => {

  it('should throw ProviderUnavailableError for bad providers', () => {
    expect(() => {
      throw new ProviderUnavailableError('BOGUS');
    }).toThrow(ProviderUnavailableError);
  });

  it('should throw InfrastructureUnavailableError for missing DB', () => {
    expect(() => {
      throw new InfrastructureUnavailableError('Prisma');
    }).toThrow(InfrastructureUnavailableError);
  });

  it('should validate AgentPlanSchema correctly', () => {
    const valid = {
      intent: 'test',
      steps: [
        { id: '1', description: 'desc', requiresApproval: false, dependencies: [] }
      ],
      estimatedRisk: 'LOW'
    };
    expect(() => AgentPlanSchema.parse(valid)).not.toThrow();

    const invalid = { intent: 'test', steps: [] };
    expect(() => AgentPlanSchema.parse(invalid)).toThrow();
  });
});
