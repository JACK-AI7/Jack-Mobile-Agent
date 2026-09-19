export class ProviderUnavailableError extends Error {
  constructor(providerName: string) {
    super(`AI Provider unavailable or not configured: ${providerName}`);
    this.name = 'ProviderUnavailableError';
  }
}
