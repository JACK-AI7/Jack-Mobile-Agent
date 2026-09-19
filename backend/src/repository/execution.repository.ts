import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service.js';

export abstract class ExecutionRepository {
  abstract createExecution(userId: string, data: any): Promise<any>;
  abstract findById(id: string, userId: string): Promise<any>;
  abstract updateState(id: string, userId: string, state: string): Promise<any>;
  abstract updateResult(id: string, userId: string, result: string): Promise<any>;
}

@Injectable()
export class PrismaExecutionRepository implements ExecutionRepository {
  constructor(private prisma: PrismaService) {}

  async createExecution(userId: string, data: any): Promise<any> {
    return this.prisma.task.create({
      data: {
        id: `exec_${Date.now()}`,
        userId: userId,
        status: 'QUEUED',
        action: data.message
      }
    });
  }

  async findById(id: string, userId: string): Promise<any> {
    const exec = await this.prisma.task.findFirst({ where: { id, userId } });
    if (!exec) throw new Error('Execution not found or unauthorized');
    return exec;
  }

  async updateState(id: string, userId: string, state: string): Promise<any> {
    const exec = await this.findById(id, userId);
    return this.prisma.task.update({
      where: { id: exec.id },
      data: { status: state }
    });
  }

  async updateResult(id: string, userId: string, result: string): Promise<any> {
    const exec = await this.findById(id, userId);
    return this.prisma.task.update({
      where: { id: exec.id },
      data: { result }
    });
  }
}
