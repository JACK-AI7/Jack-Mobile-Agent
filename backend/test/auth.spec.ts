import { describe, it, expect } from 'vitest';
import { JackAuthGuard } from '../src/auth/auth.guard.js';
import { AuthenticationFailure } from '../src/common/exceptions/authentication.error.js';
import * as jwt from 'jsonwebtoken';
import { ConfigService } from '@nestjs/config';

describe('Authentication & Tenant Isolation', () => {
  it('should reject requests without authorization header', async () => {
    const guard = new JackAuthGuard(new ConfigService());
    const mockContext = {
      switchToHttp: () => ({
        getRequest: () => ({ headers: {} })
      })
    } as any;

    await expect(guard.canActivate(mockContext)).rejects.toThrow(AuthenticationFailure);
  });

  it('should reject malformed Bearer tokens', async () => {
    const guard = new JackAuthGuard(new ConfigService());
    const mockContext = {
      switchToHttp: () => ({
        getRequest: () => ({ headers: { authorization: 'Bearer ' } })
      })
    } as any;

    await expect(guard.canActivate(mockContext)).rejects.toThrow(AuthenticationFailure);
  });

  it('should reject invalid JWT signature', async () => {
    const config = new ConfigService({ JWT_SECRET: 'secret' });
    const guard = new JackAuthGuard(config);
    
    const badToken = jwt.sign({ sub: 'user_123' }, 'wrong_secret');
    
    const mockContext = {
      switchToHttp: () => ({
        getRequest: () => ({ headers: { authorization: `Bearer ${badToken}` } })
      })
    } as any;

    await expect(guard.canActivate(mockContext)).rejects.toThrow(AuthenticationFailure);
  });

  it('should accept valid JWT and extract user', async () => {
    const config = new ConfigService({ JWT_SECRET: 'supersecret' });
    const guard = new JackAuthGuard(config);
    
    const validToken = jwt.sign({ sub: 'user_999' }, 'supersecret');
    
    const req = { headers: { authorization: `Bearer ${validToken}` } } as any;
    const mockContext = {
      switchToHttp: () => ({ getRequest: () => req })
    } as any;

    const result = await guard.canActivate(mockContext);
    expect(result).toBe(true);
    expect(req.user.id).toBe('user_999');
  });
});
