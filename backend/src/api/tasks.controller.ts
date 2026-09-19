import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { JackAuthGuard, AuthenticatedUser } from '../auth/auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { PrismaService } from '../prisma.service.js';

@Controller('tasks')
@UseGuards(JackAuthGuard)
export class TasksController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async getTasks(@CurrentUser() user: AuthenticatedUser) {
    return this.prisma.task.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  @Get(':id')
  async getTask(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.prisma.task.findUnique({
      where: { id, userId: user.id },
    });
  }
}