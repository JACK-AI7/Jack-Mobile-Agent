import { Controller, Post, Get, Param, Body, Patch, Inject, UseGuards } from '@nestjs/common';
import { AgentGenerationService } from '../agent/generation/agent.generation.js';
import { ToolRegistryService } from '../agent/registry/tool-registry.service.js';
import { DeviceCapabilityRegistry } from '../device/capability.registry.js';
import { AgentRepository } from '../repository/agent.repository.js';
import { ExecutionRepository } from '../repository/execution.repository.js';
import { MemoryRepository } from '../repository/memory.repository.js';
import { InfrastructureUnavailableError } from '../common/exceptions/infrastructure-unavailable.error.js';
import { JackAuthGuard } from '../auth/auth.guard.js';
import type { AuthenticatedUser } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';

@Controller('agents')
@UseGuards(JackAuthGuard)
export class AgentsController {
  constructor(
    private agentGen: AgentGenerationService,
    @Inject('AgentRepository') private agentRepo: AgentRepository,
    @Inject('ExecutionRepository') private executionRepo: ExecutionRepository
  ) {}

  @Post()
  async createAgent(@CurrentUser() user: AuthenticatedUser, @Body() body: { prompt: string }) {
    // Generate agent definition
    const def = await this.agentGen.generateAgentFromRequest(body.prompt);
    // Persist agent with ownership
    return this.agentRepo.create(user.id, def);
  }

  @Get()
  async getAgents(@CurrentUser() user: AuthenticatedUser) {
    return this.agentRepo.findMany(user.id);
  }

  @Post(':id/run')
  async runAgent(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    // 1. Verify agent ownership before running
    await this.agentRepo.findById(id, user.id); 
    throw new InfrastructureUnavailableError('BullMQ/Redis');
  }

  @Post('execute')
  async executeAgent(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { requestId: string, message: string, agentId?: string, conversationId?: string }
  ) {
    const targetAgentId = body.agentId || 'jack-default';
    
    // Verify agent belongs to user
    await this.agentRepo.findById(targetAgentId, user.id);
    
    // Create execution enforcing user ownership
    return this.executionRepo.createExecution(user.id, {
      agentId: targetAgentId,
      message: body.message
    });
  }
}

@Controller('capabilities')
@UseGuards(JackAuthGuard)
export class CapabilitiesController {
  constructor(private registry: DeviceCapabilityRegistry) {}

  @Get()
  getCapabilities() {
    return {
      camera: this.registry.getCapability('android.camera'),
      screen: this.registry.getCapability('android.screen_assistance'),
      search: this.registry.getCapability('backend.web_search')
    };
  }
}

@Controller('tools')
@UseGuards(JackAuthGuard)
export class ToolsController {
  constructor(private registry: ToolRegistryService) {}

  @Get()
  getTools() {
    return this.registry.getAllTools();
  }

  @Post(':id/connect')
  connectTool(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    throw new InfrastructureUnavailableError('Prisma Database');
  }
}

@Controller('memory')
@UseGuards(JackAuthGuard)
export class MemoryController {
  constructor(@Inject('MemoryRepository') private memoryRepo: MemoryRepository) {}

  @Get()
  getMemory(@CurrentUser() user: AuthenticatedUser) {
    return this.memoryRepo.findMany(user.id);
  }

  @Post()
  saveMemory(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.memoryRepo.create(user.id, body);
  }
}


