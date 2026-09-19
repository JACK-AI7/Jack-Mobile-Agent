import { z } from 'zod';
import { RiskLevel } from '../registry/tool-registry.service.js';

export const ToolInvocationSchema = z.object({
  toolName: z.string(),
  inputs: z.record(z.string(), z.any())
});

export const PlanStepSchema = z.object({
  id: z.string(),
  description: z.string(),
  tool: ToolInvocationSchema.optional(),
  requiresApproval: z.boolean().default(false),
  dependencies: z.array(z.string()).default([])
});

export const AgentPlanSchema = z.object({
  intent: z.string(),
  steps: z.array(PlanStepSchema),
  estimatedRisk: z.nativeEnum(RiskLevel)
});

export type AgentPlan = z.infer<typeof AgentPlanSchema>;
export type PlanStep = z.infer<typeof PlanStepSchema>;
