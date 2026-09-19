import { HttpException, HttpStatus } from '@nestjs/common';

export class AuthorizationFailure extends HttpException {
  constructor(message: string = 'Insufficient permissions') {
    super(message, HttpStatus.FORBIDDEN);
    this.name = 'AuthorizationFailure';
  }
}
