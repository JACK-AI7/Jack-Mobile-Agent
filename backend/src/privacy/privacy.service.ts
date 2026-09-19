import { Injectable, Logger } from '@nestjs/common';

export enum DataClassification {
  PUBLIC = 'PUBLIC',
  PRIVATE = 'PRIVATE',
  SENSITIVE = 'SENSITIVE',
  HIGHLY_SENSITIVE = 'HIGHLY_SENSITIVE'
}

@Injectable()
export class SensitiveDataDetector {
  private readonly logger = new Logger(SensitiveDataDetector.name);

  // Detects OTPs, API keys, CVVs, etc.
  classifyText(text: string): { classification: DataClassification, redacted: string } {
    let redacted = text;
    let classification = DataClassification.PUBLIC;

    // Simple Regex Heuristics (In production, use advanced NLP / DLP)
    
    // OTP/PIN heuristic (4-6 digits in isolation)
    if (/\b\d{4,6}\b/.test(text)) {
      classification = DataClassification.HIGHLY_SENSITIVE;
      redacted = redacted.replace(/\b\d{4,6}\b/g, '[REDACTED_OTP_OR_PIN]');
    }

    // JWT/API Key heuristic
    if (/ey[a-zA-Z0-9_=]+/.test(text) || /sk-[a-zA-Z0-9]{20,}/.test(text)) {
      classification = DataClassification.HIGHLY_SENSITIVE;
      redacted = redacted.replace(/ey[a-zA-Z0-9_=]+/g, '[REDACTED_TOKEN]');
      redacted = redacted.replace(/sk-[a-zA-Z0-9]{20,}/g, '[REDACTED_API_KEY]');
    }

    // Email heuristic
    if (/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/.test(text)) {
      // Elevate to private if personal info is found
      if (classification === DataClassification.PUBLIC) {
        classification = DataClassification.PRIVATE;
      }
    }

    return { classification, redacted };
  }
}

@Injectable()
export class PrivacyPolicyEngine {
  private readonly logger = new Logger(PrivacyPolicyEngine.name);

  constructor(private detector: SensitiveDataDetector) {}

  /**
   * Evaluates if data is safe to send to a specific provider based on its privacy policy
   */
  canSendToProvider(text: string, providerTrainsOnData: boolean): { allowed: boolean, safeText: string } {
    const { classification, redacted } = this.detector.classifyText(text);

    this.logger.log(`Data classified as ${classification}`);

    if (classification === DataClassification.HIGHLY_SENSITIVE) {
      this.logger.warn(`BLOCKED: Highly sensitive data detected. Redacting before AI context.`);
      return { allowed: true, safeText: redacted }; // We send the redacted version safely
    }

    if (classification === DataClassification.SENSITIVE && providerTrainsOnData) {
      this.logger.warn(`BLOCKED: Provider trains on data, cannot send SENSITIVE content.`);
      return { allowed: false, safeText: "" };
    }

    return { allowed: true, safeText: redacted };
  }
}
