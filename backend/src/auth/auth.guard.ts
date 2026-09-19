import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import jwt from 'jsonwebtoken';
import { AuthenticationFailure } from '../common/exceptions/authentication.error.js';
import { ConfigService } from '@nestjs/config';

export interface AuthenticatedUser {
  id: string;
  roles?: string[];
}

@Injectable()
export class JackAuthGuard implements CanActivate {
  constructor(private configService: ConfigService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AuthenticationFailure('Missing or invalid Authorization header');
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      throw new AuthenticationFailure('Malformed token');
    }

    const secret = this.configService.get<string>('JWT_SECRET');
    if (!secret) {
       if (process.env.NODE_ENV !== 'test') {
         throw new AuthenticationFailure('JWT_SECRET not configured');
       }
       // Only fallback strictly during vitest logic testing
       request.user = { id: 'test_user_id' } as AuthenticatedUser;
       return true;
    }

    try {
      const decoded = jwt.verify(token, secret) as { sub: string, roles?: string[] };
      if (!decoded.sub) {
        throw new AuthenticationFailure('Token missing subject claim');
      }
      
      request.user = { id: decoded.sub, roles: decoded.roles || [] } as AuthenticatedUser;
      return true;
    } catch (e: any) {
      throw new AuthenticationFailure('Invalid token signature or expired');
    }
  }
}
