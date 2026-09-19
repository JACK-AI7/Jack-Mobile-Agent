export class InfrastructureUnavailableError extends Error {
  constructor(service: string) {
    super(`Infrastructure unavailable: ${service}`);
    this.name = 'InfrastructureUnavailableError';
  }
}
