import { Injectable, Logger } from '@nestjs/common';
import { AgentGenerationService } from '../generation/agent.generation.js';
import { MemoryService, MemoryType } from '../memory/memory.service.js';

export enum RiskLevel {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL'
}

export enum ToolExecutionStatus {
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
  PERMISSION_REQUIRED = 'PERMISSION_REQUIRED',
  UNSUPPORTED = 'UNSUPPORTED',
  USER_CANCELLED = 'USER_CANCELLED'
}

export interface ToolDefinition {
  name: string;
  description: string;
  category: string;
  inputSchema: any;
  outputSchema: any;
  requiredPermissions: string[];
  riskLevel: RiskLevel;
  timeoutMs: number;
  retryPolicy: { maxRetries: number; backoffMs: number };
  availability: 'AVAILABLE' | 'UNAVAILABLE' | 'REQUIRES_SETUP';
  execute: (userId: string, input: any) => Promise<{ status: ToolExecutionStatus; result?: any; error?: string }>;
}

@Injectable()
export class ToolRegistryService {
  private readonly logger = new Logger(ToolRegistryService.name);
  private tools = new Map<string, ToolDefinition>();

  constructor(
    private agentGen: AgentGenerationService,
    private memoryService: MemoryService
  ) {
    this.registerInternalTools();
  }

  private registerInternalTools() {
    this.registerTool({
      name: 'CreateAgent',
      description: 'Creates a new JACK AI Agent.',
      category: 'INTERNAL',
      inputSchema: { type: 'object', properties: { prompt: { type: 'string' } } },
      outputSchema: { type: 'object', properties: { success: { type: 'boolean' } } },
      requiredPermissions: [],
      riskLevel: RiskLevel.LOW,
      timeoutMs: 5000,
      retryPolicy: { maxRetries: 0, backoffMs: 0 },
      availability: 'AVAILABLE',
      execute: async (userId, input) => {
        try {
          const agent = await this.agentGen.generateAgentFromRequest(input.prompt);
          // Tool would need to call agentRepo.create here, but AgentGen just returns definition
          return { status: ToolExecutionStatus.SUCCESS, result: agent };
        } catch (e: any) {
          return { status: ToolExecutionStatus.FAILED, error: e.message };
        }
      }
    });

    this.registerTool({
      name: 'SaveMemory',
      description: 'Saves a memory for the user.',
      category: 'INTERNAL',
      inputSchema: { type: 'object', properties: { type: { type: 'string' }, content: { type: 'string' } } },
      outputSchema: { type: 'object', properties: { success: { type: 'boolean' } } },
      requiredPermissions: [],
      riskLevel: RiskLevel.LOW,
      timeoutMs: 5000,
      retryPolicy: { maxRetries: 0, backoffMs: 0 },
      availability: 'AVAILABLE',
      execute: async (userId, input) => {
        try {
          const mem = await this.memoryService.save(userId, input.type as MemoryType, input.content);
          return { status: ToolExecutionStatus.SUCCESS, result: mem };
        } catch (e: any) {
          return { status: ToolExecutionStatus.FAILED, error: e.message };
        }
      }
    });
  }

  registerTool(tool: ToolDefinition) {
    this.logger.log(`Registering tool: ${tool.name} (Risk: ${tool.riskLevel})`);
    this.tools.set(tool.name, tool);
  }

  getTool(name: string): ToolDefinition | undefined {
    return this.tools.get(name);
  }

  getAllTools(): ToolDefinition[] {
    return Array.from(this.tools.values());
  }

  async executeTool(name: string, userId: string, input: any): Promise<{ status: ToolExecutionStatus; result?: any; error?: string }> {
    const tool = this.getTool(name);
    if (!tool) {
      return { status: ToolExecutionStatus.UNSUPPORTED, error: `Tool ${name} not found.` };
    }
    
    this.logger.log(`Executing tool: ${name}`);
    try {
      return await tool.execute(userId, input);
    } catch (e: any) {
      this.logger.error(`Tool execution failed: ${e.message}`);
      return { status: ToolExecutionStatus.FAILED, error: e.message };
    }
  }
}
