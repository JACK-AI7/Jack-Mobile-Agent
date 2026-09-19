import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service.js';

export abstract class MemoryRepository {
  abstract findMany(userId: string): Promise<any[]>;
  abstract create(userId: string, data: any): Promise<any>;
}

@Injectable()
export class PrismaMemoryRepository implements MemoryRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findMany(userId: string): Promise<any[]> {
    return this.prisma.memory.findMany({ where: { userId } });
  }

  async create(userId: string, data: any): Promise<any> {
    return this.prisma.memory.create({
      data: {
        userId,
        type: data.type ?? 'SESSION',
        content: data.content ?? '',
        context: data.context ?? null,
      },
    });
  }
}
