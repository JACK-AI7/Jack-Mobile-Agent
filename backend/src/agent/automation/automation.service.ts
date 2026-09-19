import { Injectable, Logger } from '@nestjs/common';
import { Queue } from 'bullmq';
import { InjectQueue } from '@nestjs/bullmq';

@Injectable()
export class AutomationService {
  private readonly logger = new Logger(AutomationService.name);

  constructor(@InjectQueue('agent-tasks') private agentQueue: Queue) {}

  async createScheduledAutomation(userId: string, agentId: string, name: string, cron: string, intent: string) {
    this.logger.log(`Creating automation: ${name} (${cron}) for user ${userId}`);
    
    try {
      await this.agentQueue.add(
        'scheduled-agent-task',
        { intent, source: 'automation', userId, agentId },
        { repeat: { pattern: cron } } as any
      );
      return { success: true, name, cron };
    } catch (e) {
      const InfrastructureUnavailableError = require('../../common/exceptions/infrastructure-unavailable.error.js').InfrastructureUnavailableError;
      throw new InfrastructureUnavailableError('Redis/BullMQ');
    }
  }

  async runManual(userId: string, agentId: string, intent: string) {
    this.logger.log(`Manual trigger: ${intent} for user ${userId}`);
    try {
      await this.agentQueue.add('manual-agent-task', { intent, source: 'manual', userId, agentId });
      return { success: true, queued: true };
    } catch (e) {
      const InfrastructureUnavailableError = require('../../common/exceptions/infrastructure-unavailable.error.js').InfrastructureUnavailableError;
      throw new InfrastructureUnavailableError('Redis/BullMQ');
    }
  }
}
