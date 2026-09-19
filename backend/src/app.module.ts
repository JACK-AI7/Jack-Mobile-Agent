import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BullModule } from '@nestjs/bullmq';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { OrbGateway } from './gateway/orb.gateway.js';
import { AIProviderService } from './agent/ai-provider.service.js';
import { AgentRuntime } from './agent/agent.runtime.js';
import { AgentExecutionProcessor } from './bullmq/agent.processor.js';
import { ToolRegistryService } from './agent/registry/tool-registry.service.js';
import { AgentPlannerService } from './agent/planner/agent.planner.js';
import { AgentGenerationService } from './agent/generation/agent.generation.js';
import { DeviceCapabilityRegistry } from './device/capability.registry.js';
import { PrivacyPolicyEngine, SensitiveDataDetector } from './privacy/privacy.service.js';
import { AgentsController, CapabilitiesController, ToolsController, MemoryController } from './api/jack.controller.js';
import { MemoryService } from './agent/memory/memory.service.js';
import { AutomationService } from './agent/automation/automation.service.js';
import { AIProviderRouter } from './agent/provider/ai.router.js';
import { AuthController } from './auth/auth.controller.js';
import { HealthController } from './health/health.controller.js';
import { TasksController } from './api/tasks.controller.js';
import { AutomationsController } from './api/automations.controller.js';

import { PrismaAgentRepository } from './repository/agent.repository.js';
import { PrismaExecutionRepository } from './repository/execution.repository.js';
import { PrismaMemoryRepository } from './repository/memory.repository.js';
import { PrismaService } from './prisma.service.js';

// Determine the run mode. Defaults to 'ALL' for local dev.
const runMode = process.env.RUN_MODE || 'ALL';
const isWorker = runMode === 'WORKER' || runMode === 'ALL';
const isApi = runMode === 'API' || runMode === 'ALL';

const controllers = [];
if (isApi) {
  controllers.push(
    AppController,
    AuthController,
    AgentsController,
    CapabilitiesController,
    ToolsController,
    MemoryController,
    HealthController,
    TasksController,
    AutomationsController
  );
}

const providers: any[] = [
  PrismaService,
  AppService, 
  OrbGateway, 
  AIProviderService, 
  AgentRuntime, 
  ToolRegistryService,
  AgentPlannerService,
  AgentGenerationService,
  DeviceCapabilityRegistry,
  PrivacyPolicyEngine,
  SensitiveDataDetector,
  MemoryService,
  AutomationService,
  AIProviderRouter,
  { provide: 'AgentRepository', useClass: PrismaAgentRepository },
  { provide: 'ExecutionRepository', useClass: PrismaExecutionRepository },
  { provide: 'MemoryRepository', useClass: PrismaMemoryRepository }
];

if (isWorker) {
  providers.push(AgentExecutionProcessor);
}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => {
        const redisUrl = configService.get('REDIS_URL');
        if (redisUrl) {
          return {
            connection: {
              url: redisUrl,
            },
          };
        }
        return {
          connection: {
            host: configService.get('REDIS_HOST') || 'localhost',
            port: parseInt(configService.get('REDIS_PORT') || '6379', 10),
          },
        };
      },
      inject: [ConfigService],
    }),
    BullModule.registerQueue({
      name: 'agent-tasks',
    }),
  ],
  controllers,
  providers,
})
export class AppModule {}
