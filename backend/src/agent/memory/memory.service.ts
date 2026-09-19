import { Injectable, Logger, Inject } from '@nestjs/common';
import { SensitiveDataDetector, DataClassification } from '../../privacy/privacy.service.js';
import { MemoryRepository } from '../../repository/memory.repository.js';

export enum MemoryType {
  SESSION = 'SESSION',
  SHORT_TERM = 'SHORT_TERM',
  LONG_TERM = 'LONG_TERM',
  PREFERENCE = 'PREFERENCE',
  PROJECT = 'PROJECT',
  TASK = 'TASK',
  AGENT = 'AGENT',
  WORKFLOW = 'WORKFLOW'
}

export interface Memory {
  id: string;
  type: MemoryType;
  content: string;
}

@Injectable()
export class MemoryService {
  private readonly logger = new Logger(MemoryService.name);

  constructor(
    private privacyDetector: SensitiveDataDetector,
    @Inject('MemoryRepository') private memoryRepo: MemoryRepository
  ) {}

  async save(userId: string, type: MemoryType, content: string): Promise<Memory> {
    const { classification } = this.privacyDetector.classifyText(content);
    
    if (classification === DataClassification.HIGHLY_SENSITIVE) {
      this.logger.warn(`Rejected memory save: Content is HIGHLY_SENSITIVE`);
      throw new Error("Cannot save HIGHLY_SENSITIVE data to memory.");
    }

    this.logger.log(`Saving memory (type: ${type})`);
    return this.memoryRepo.create(userId, { type, content });
  }

  async search(userId: string, query: string): Promise<Memory[]> {
    // Await vector/full-text search in Prisma
    return this.memoryRepo.findMany(userId);
  }

  async delete(userId: string, id: string): Promise<boolean> {
    throw new Error('Not implemented'); // Requires delete in repo
  }
}
