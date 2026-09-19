import { SensitiveDataDetector, DataClassification, PrivacyPolicyEngine } from '../src/privacy/privacy.service.js';
import { describe, it, expect, beforeEach } from 'vitest';

describe('SensitiveDataDetector', () => {
  let detector: SensitiveDataDetector;
  let engine: PrivacyPolicyEngine;

  beforeEach(() => {
    detector = new SensitiveDataDetector();
    engine = new PrivacyPolicyEngine(detector);
  });

  it('should redact 6-digit OTPs and classify as HIGHLY_SENSITIVE', () => {
    const result = detector.classifyText('Your login code is 123456 do not share it.');
    expect(result.classification).toBe(DataClassification.HIGHLY_SENSITIVE);
    expect(result.redacted).toBe('Your login code is [REDACTED_OTP_OR_PIN] do not share it.');
  });

  it('should redact API keys', () => {
    const result = detector.classifyText('My key is sk-1234567890abcdefghij12345');
    expect(result.classification).toBe(DataClassification.HIGHLY_SENSITIVE);
    expect(result.redacted).toBe('My key is [REDACTED_API_KEY]');
  });

  it('should allow PUBLIC data to pass through PrivacyEngine', () => {
    const result = engine.canSendToProvider('What is the weather today?', true);
    expect(result.allowed).toBe(true);
    expect(result.safeText).toBe('What is the weather today?');
  });

  it('should send redacted text for HIGHLY_SENSITIVE data', () => {
    const result = engine.canSendToProvider('My OTP is 998877', false);
    expect(result.allowed).toBe(true);
    expect(result.safeText).toBe('My OTP is [REDACTED_OTP_OR_PIN]');
  });
});
