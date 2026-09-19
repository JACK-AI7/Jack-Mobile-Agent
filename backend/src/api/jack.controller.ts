import { Controller, Post, Get, Param, Body, Patch, Delete, Inject, UseGuards } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
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
    @Inject('ExecutionRepository') private executionRepo: ExecutionRepository,
    @InjectQueue('agent-tasks') private agentQueue: Queue
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

  @Get(':id')
  async getAgent(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.agentRepo.findById(id, user.id);
  }

  @Patch(':id')
  async updateAgent(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Body() body: any) {
    return this.agentRepo.update(id, user.id, body);
  }

  @Delete(':id')
  async deleteAgent(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.agentRepo.delete(id, user.id);
  }

  @Post(':id/run')
  async runAgent(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    // 1. Verify agent ownership before running
    await this.agentRepo.findById(id, user.id); 
    
    // Create execution for specific agent
    const exec = await this.executionRepo.createExecution(user.id, {
      agentId: id,
      message: 'Run agent workflow'
    });
    
    await this.agentQueue.add('execute-task', {
      executionId: exec.id,
      userId: user.id
    });
    
    return exec;
  }

  @Post('execute')
  async executeAgent(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { requestId: string, message: string, agentId?: string, conversationId?: string }
  ) {
    const targetAgentId = body.agentId || 'jack-default';
    
    // Verify agent belongs to user if it is not the default
    if (targetAgentId !== 'jack-default') {
      await this.agentRepo.findById(targetAgentId, user.id);
    }
    
    // Create execution enforcing user ownership
    const exec = await this.executionRepo.createExecution(user.id, {
      agentId: targetAgentId,
      message: body.message
    });
    
    // Dispatch to BullMQ worker
    await this.agentQueue.add('execute-task', {
      executionId: exec.id,
      userId: user.id
    });
    
    return {
      executionId: exec.id,
      agentId: targetAgentId,
      status: exec.status,
      result: exec.result
    };
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
    // For now, return a success status, but in a real app this would store the OAuth token
    return { status: 'CONNECTED', toolId: id };
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


