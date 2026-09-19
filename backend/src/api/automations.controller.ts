import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards } from '@nestjs/common';
import { JackAuthGuard } from '../auth/auth.guard.js';
import type { AuthenticatedUser } from '../auth/auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { PrismaService } from '../prisma.service.js';

@Controller('automations')
@UseGuards(JackAuthGuard)
export class AutomationsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async getAutomations(@CurrentUser() user: AuthenticatedUser) {
    return this.prisma.automation.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  @Post()
  async createAutomation(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.prisma.automation.create({
      data: {
        userId: user.id,
        name: body.name || 'New Automation',
        schedule: body.schedule || '* * * * *',
        isActive: body.isActive ?? true,
      },
    });
  }

  @Patch(':id')
  async updateAutomation(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Body() body: any) {
    return this.prisma.automation.update({
      where: { id, userId: user.id },
      data: body,
    });
  }

  @Delete(':id')
  async deleteAutomation(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.prisma.automation.delete({
      where: { id, userId: user.id },
    });
  }
}