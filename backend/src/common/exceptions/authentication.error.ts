import { HttpException, HttpStatus } from '@nestjs/common';

export class AuthenticationFailure extends HttpException {
  constructor(message: string = 'Authentication required') {
    super(message, HttpStatus.UNAUTHORIZED);
    this.name = 'AuthenticationFailure';
  }
}
