export enum OrbState {
  IDLE = 'IDLE',
  LISTENING = 'LISTENING',
  THINKING = 'THINKING',
  PLANNING = 'PLANNING',
  EXECUTING = 'EXECUTING',
  SEARCHING = 'SEARCHING',
  USING_TOOL = 'USING_TOOL',
  WAITING_FOR_USER = 'WAITING_FOR_USER',
  WAITING_FOR_APPROVAL = 'WAITING_FOR_APPROVAL',
  SPEAKING = 'SPEAKING',
  SUCCESS = 'SUCCESS',
  ERROR = 'ERROR',
  OFFLINE = 'OFFLINE',
  SLEEPING = 'SLEEPING',
  WAKE = 'WAKE'
}

export interface AgentRealtimeEvent {
  jobId: string;
  agentId?: string;
  taskId?: string;
  timestamp: string;
}

export interface AgentStartedEvent extends AgentRealtimeEvent {
  intent: string;
}

export interface AgentPlanningEvent extends AgentRealtimeEvent {
  planSize: number;
}

export interface AgentToolStartedEvent extends AgentRealtimeEvent {
  toolName: string;
  toolDescription: string;
}

export interface AgentToolCompletedEvent extends AgentRealtimeEvent {
  toolName: string;
  success: boolean;
}

export interface AgentApprovalRequiredEvent extends AgentRealtimeEvent {
  reason: string;
  riskLevel: string;
}

export interface AgentCompletedEvent extends AgentRealtimeEvent {
  finalResult: string;
}

export interface AgentFailedEvent extends AgentRealtimeEvent {
  error: string;
  retryable: boolean;
}
