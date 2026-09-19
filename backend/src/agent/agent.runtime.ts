import { Injectable, Logger, Inject } from '@nestjs/common';
import { AgentPlannerService } from './planner/agent.planner.js';
import { ToolRegistryService } from './registry/tool-registry.service.js';
import { MemoryService } from './memory/memory.service.js';
import { OrbGateway } from '../gateway/orb.gateway.js';
import { OrbState } from '../gateway/events/socket.events.js';
import { AuthorizationFailure } from '../common/exceptions/authorization.error.js';
import { ExecutionRepository } from '../repository/execution.repository.js';
import { AgentRepository } from '../repository/agent.repository.js';

export enum AgentState {
  QUEUED = 'QUEUED',
  PLANNING = 'PLANNING',
  WAITING_FOR_APPROVAL = 'WAITING_FOR_APPROVAL',
  RUNNING = 'RUNNING',
  WAITING_FOR_TOOL = 'WAITING_FOR_TOOL',
  PAUSED = 'PAUSED',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED'
}

@Injectable()
export class AgentRuntime {
  private readonly logger = new Logger(AgentRuntime.name);

  constructor(
    private planner: AgentPlannerService,
    private toolRegistry: ToolRegistryService,
    private memoryService: MemoryService,
    private orbGateway: OrbGateway,
    @Inject('ExecutionRepository') private executionRepo: ExecutionRepository,
    @Inject('AgentRepository') private agentRepo: AgentRepository
  ) {}

  async executeTask(executionId: string, userId: string) {
    this.logger.log(`Starting execution for executionId: ${executionId}`);

    // 1. Load execution and validate ownership
    const execution = await this.executionRepo.findById(executionId, userId);

    try {
      // 2. Transition to PLANNING
      await this.executionRepo.updateState(executionId, userId, AgentState.PLANNING);
      this.orbGateway.emitOrbState(OrbState.PLANNING);
      this.logger.log(`Execution ${executionId} → PLANNING`);

      // 3. Create executable plan from the task action stored in DB
      const { plan } = await this.planner.createExecutablePlan(execution.action);

      // 4. Transition to RUNNING
      await this.executionRepo.updateState(executionId, userId, AgentState.RUNNING);
      this.orbGateway.emitOrbState(OrbState.EXECUTING);
      this.logger.log(`Execution ${executionId} → RUNNING`);

      // 5. Summarise plan steps as the result
      const stepSummary = plan.steps
        .map((s: any, i: number) => `${i + 1}. ${s.description}`)
        .join('\n');
      const result = `Completed plan for: "${execution.action}"\n${stepSummary}`;

      // 6. Complete
      await this.executionRepo.updateState(executionId, userId, AgentState.COMPLETED);
      // Persist result
      await this.executionRepo.updateResult(executionId, userId, result);
      this.orbGateway.emitOrbState(OrbState.SUCCESS);
      this.logger.log(`Execution ${executionId} → COMPLETED`);

      return { executionId, status: AgentState.COMPLETED, result };
    } catch (err: any) {
      const errorMessage = err?.message ?? 'Unknown error';
      this.logger.error(`Execution ${executionId} failed: ${errorMessage}`);

      await this.executionRepo.updateState(executionId, userId, AgentState.FAILED);
      await this.executionRepo.updateResult(executionId, userId, errorMessage);
      this.orbGateway.emitOrbState(OrbState.ERROR);

      return { executionId, status: AgentState.FAILED, result: errorMessage };
    }
  }

  private updateState(executionId: string, userId: string, state: AgentState) {
    this.logger.log(`Execution ${executionId} transitioned to ${state}`);
  }
}
