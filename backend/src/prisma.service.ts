import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    try {
      await this.$connect();
      console.log('✅ Prisma connected to the database.');
    } catch (error) {
      console.error('❌ Prisma Database Connection Error:', error);
      console.error('The server will remain online, but database operations will fail until fixed.');
    }
  }
}
