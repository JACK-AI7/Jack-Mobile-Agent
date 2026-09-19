import {
  Controller,
  Post,
  Body,
  BadRequestException,
  UnauthorizedException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma.service.js';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';

interface RegisterDto {
  email: string;
  password: string;
  name: string;
}

interface LoginDto {
  email: string;
  password: string;
}

interface AuthResponse {
  accessToken: string;
  userId: string;
  email: string;
}

@Controller('auth')
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  @Post('register')
  async register(@Body() body: RegisterDto): Promise<AuthResponse> {
    if (!body.email || !body.password || !body.name) {
      throw new BadRequestException('email, password, and name are required');
    }

    const existing = await this.prisma.user.findUnique({
      where: { email: body.email },
    });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(body.password, 12);

    const user = await this.prisma.user.create({
      data: {
        email: body.email,
        name: body.name,
        passwordHash,
      },
    });

    this.logger.log(`User registered: ${user.id}`);

    const accessToken = this.signToken(user.id);
    return { accessToken, userId: user.id, email: user.email };
  }

  @Post('login')
  async login(@Body() body: LoginDto): Promise<AuthResponse> {
    if (!body.email || !body.password) {
      throw new BadRequestException('email and password are required');
    }

    const user = await this.prisma.user.findUnique({
      where: { email: body.email },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const valid = await bcrypt.compare(body.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    this.logger.log(`User authenticated: ${user.id}`);

    const accessToken = this.signToken(user.id);
    return { accessToken, userId: user.id, email: user.email };
  }

  private signToken(userId: string): string {
    const secret = this.config.get<string>('JWT_SECRET');
    if (!secret) {
      throw new Error('JWT_SECRET is not configured');
    }
    return jwt.sign({ sub: userId }, secret, { expiresIn: '7d' });
  }
}
