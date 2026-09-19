import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  OnGatewayConnection,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import { OrbState, AgentRealtimeEvent } from './events/socket.events.js';

@WebSocketGateway({ cors: true })
export class OrbGateway implements OnGatewayConnection {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(OrbGateway.name);

  constructor(private readonly config: ConfigService) {}

  handleConnection(socket: Socket) {
    const token = socket.handshake.auth?.token as string | undefined;

    if (!token) {
      this.logger.warn(`WS connection rejected: no token (socketId=${socket.id})`);
      socket.disconnect(true);
      return;
    }

    const secret = this.config.get<string>('JWT_SECRET');
    if (!secret) {
      this.logger.error('JWT_SECRET not configured — rejecting WS connection');
      socket.disconnect(true);
      return;
    }

    try {
      const decoded = jwt.verify(token, secret) as { sub: string };
      if (!decoded.sub) {
        socket.disconnect(true);
        return;
      }
      socket.data.userId = decoded.sub;
      this.logger.log(`WS connected: userId=${decoded.sub} socketId=${socket.id}`);
    } catch {
      this.logger.warn(`WS connection rejected: invalid token (socketId=${socket.id})`);
      socket.disconnect(true);
    }
  }

  emitOrbState(state: OrbState) {
    this.logger.log(`Emitting Orb State: ${state}`);
    this.server.emit('orb_state_change', { state });
  }

  emitAgentEvent(eventName: string, payload: AgentRealtimeEvent) {
    this.server.emit(eventName, payload);
  }

  // Sends the current task progress to the mobile app
  emitAgentProgress(message: string) {
    this.server.emit('agent_progress', { message });
  }

  @SubscribeMessage('voice_command')
  async handleVoiceCommand(@MessageBody() data: { audioText: string }) {
    this.logger.log(`Received command: ${data.audioText}`);
    this.emitOrbState(OrbState.THINKING);
    // In the full implementation, this routes to the AgentExecutor and BullMQ
  }
}
