import { Injectable, Logger } from '@nestjs/common';

export enum CapabilityState {
  SUPPORTED = 'SUPPORTED',
  AVAILABLE = 'AVAILABLE',
  PERMISSION_REQUIRED = 'PERMISSION_REQUIRED',
  DISABLED = 'DISABLED',
  UNSUPPORTED = 'UNSUPPORTED',
  PLATFORM_LIMITED = 'PLATFORM_LIMITED'
}

export interface DeviceCapability {
  id: string;
  name: string;
  category: string;
  state: CapabilityState;
  requiresNative: boolean;
  requiresUserApproval: boolean;
}

@Injectable()
export class DeviceCapabilityRegistry {
  private readonly logger = new Logger(DeviceCapabilityRegistry.name);
  private capabilities = new Map<string, DeviceCapability>();

  constructor() {
    this.initializeDefaultMatrix();
  }

  private initializeDefaultMatrix() {
    // Default matrix based on the Master Prompt requirements
    this.register({
      id: 'android.camera',
      name: 'Camera',
      category: 'VISION',
      state: CapabilityState.PERMISSION_REQUIRED,
      requiresNative: true,
      requiresUserApproval: true
    });

    this.register({
      id: 'android.screen_assistance',
      name: 'Screen Automation',
      category: 'ACCESSIBILITY',
      state: CapabilityState.PLATFORM_LIMITED,
      requiresNative: true,
      requiresUserApproval: true
    });

    this.register({
      id: 'backend.web_search',
      name: 'Web Search',
      category: 'RESEARCH',
      state: CapabilityState.AVAILABLE,
      requiresNative: false,
      requiresUserApproval: false
    });
  }

  register(cap: DeviceCapability) {
    this.capabilities.set(cap.id, cap);
  }

  getCapability(id: string): DeviceCapability | undefined {
    return this.capabilities.get(id);
  }

  checkCapability(id: string): boolean {
    const cap = this.getCapability(id);
    if (!cap) return false;
    return cap.state === CapabilityState.AVAILABLE || cap.state === CapabilityState.SUPPORTED;
  }
}
