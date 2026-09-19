import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service.js';

export abstract class AgentRepository {
  abstract findMany(userId: string): Promise<any[]>;
  abstract findById(id: string, userId: string): Promise<any>;
  abstract create(userId: string, data: any): Promise<any>;
}

@Injectable()
export class PrismaAgentRepository implements AgentRepository {
  constructor(private prisma: PrismaService) {}

  async findMany(userId: string): Promise<any[]> {
    return this.prisma.agent.findMany({ where: { userId } });
  }

  async findById(id: string, userId: string): Promise<any> {
    const agent = await this.prisma.agent.findFirst({ where: { id, userId } });
    if (!agent) throw new Error('Agent not found or unauthorized');
    return agent;
  }

  async create(userId: string, data: any): Promise<any> {
    return this.prisma.agent.create({
      data: {
        id: data.id || `agent_${Date.now()}`,
        name: data.name || 'Unnamed Agent',
        userId: userId,
        isActive: true
      }
    });
  }
}
