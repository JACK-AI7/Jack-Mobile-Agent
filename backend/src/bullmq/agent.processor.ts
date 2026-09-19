import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Injectable, Logger } from '@nestjs/common';
import { OrbGateway } from '../gateway/orb.gateway.js';
import { OrbState } from '../gateway/events/socket.events.js';
import { AIProviderService } from '../agent/ai-provider.service.js';
import { AgentRuntime } from '../agent/agent.runtime.js';

@Processor('agent-tasks')
@Injectable()
export class AgentExecutionProcessor extends WorkerHost {
  private readonly logger = new Logger(AgentExecutionProcessor.name);

  constructor(
    private orbGateway: OrbGateway,
    private aiProvider: AIProviderService,
    private agentRuntime: AgentRuntime
  ) {
    super();
  }

  async process(job: Job<{ executionId: string; userId: string }, any, string>): Promise<any> {
    const safeLogData = {
      jobId: job.id,
      jobName: job.name,
      executionId: job.data?.executionId,
      userId: job.data?.userId,
    };
    this.logger.log(`Processing job`, safeLogData);
    
    try {
      this.orbGateway.emitOrbState(OrbState.THINKING);
      
      const result = await this.agentRuntime.executeTask(job.data.executionId, job.data.userId);
      
      this.orbGateway.emitOrbState(OrbState.SUCCESS);
      
      return result;
    } catch (error) {
      this.logger.error(`Job ${job.id} failed:`, error);
      this.orbGateway.emitOrbState(OrbState.ERROR);
      throw error;
    }
  }
}
