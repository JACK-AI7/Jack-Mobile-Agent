<div align="center">
  
# 📱 Jack Mobile Agent
**The Next-Generation Autonomous AI Agent for Mobile Devices**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Socket.io](https://img.shields.io/badge/Socket.io-010101?&style=for-the-badge&logo=Socket.io&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

</div>

---

## 📖 About the Project

**Jack Mobile Agent** is a cutting-edge, autonomous AI interface built entirely in Flutter. Engineered to bridge the gap between complex Large Language Model (LLM) inference and native on-device execution, Jack provides users with an intelligent, proactive digital assistant. 

Unlike traditional chatbots that simply return text, Jack is an **Agentic System**. It parses natural language into actionable, multi-step execution plans, interfacing directly with native device capabilities. Powered by a robust backend architecture (NestJS, PostgreSQL, Redis, BullMQ) and utilizing Groq's high-speed inference, Jack represents the future of mobile-AI interaction.

The centerpiece of the application is the **Liquid Orb UI**—a visually stunning, fluid interface that provides real-time, WebSocket-driven feedback reflecting the AI's internal cognitive states (Thinking, Planning, Executing, and Success).

---

## ✨ Core Features & Capabilities

### 🧠 Agentic Autonomy
Jack doesn't just chat; it *acts*. By leveraging advanced tool-calling and prompt engineering, the agent can structure complex plans, execute native tools, and evaluate its own success autonomously.

### ⚡ Blazing Fast Execution
Built to integrate with **Groq's LPU** (Language Processing Unit) architecture via the backend worker, Jack delivers near-instantaneous reasoning and tool-selection capabilities using state-of-the-art models like `llama3-8b-8192`.

### 🔄 Real-Time Telemetry (Socket.IO)
Jack relies on a deeply integrated WebSocket layer to synchronize the mobile UI with the backend execution engine. Users watch the AI "think" and "act" in absolute real-time without manual polling or loading screens.

### 🎨 Premium UI/UX Design
- **The Jack Orb**: A dynamic, mesh-gradient orb that physically morphs and pulses based on the agent's real-time lifecycle.
- **Glassmorphism**: Premium frosted-glass overlays and deep obsidian color palettes create a sleek, futuristic aesthetic.

### 🔒 Enterprise-Grade Security
- **Strict Tenant Isolation**: JWT-based authentication ensures user data and agent memories are strictly partitioned.
- **Secure Hardware Storage**: Authentication tokens are encrypted and stored in the native device keystore via `flutter_secure_storage`.
- **Zero Client-Side Secrets**: All LLM API keys and sensitive infrastructural credentials remain strictly confined to the backend server.

---

## 🏗️ System Architecture

The Jack ecosystem is a masterclass in modern distributed systems, divided into strict boundaries of responsibility:

1. **Client Presentation Layer (Flutter)**: Handles UI rendering, WebSocket subscriptions, secure storage, and device-level hardware integrations.
2. **RESTful Gateway (`jack-api`)**: A NestJS edge server that handles JWT authentication, request validation, and Socket.IO bridging.
3. **Message Broker (Redis + BullMQ)**: Ensures reliable, asynchronous task queuing and decoupling of HTTP requests from heavy AI inference workloads.
4. **Agent Worker (`jack-worker`)**: The brain of the operation. This private background service processes queue items, communicates securely with Groq, evaluates tool execution logic, and persists results to the database.
5. **Persistence Layer (PostgreSQL)**: Stores user telemetry, agent execution history, long-term memory, and tool definitions via Prisma ORM.

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable release)
- [Dart SDK](https://dart.dev/get-dart)
- A running instance of the **Jack Backend Infrastructure** (NestJS API, Worker, Postgres, Redis)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/JACK-AI7/Jack-Mobile-Agent.git
   cd Jack-Mobile-Agent
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure the Environment:**
   Navigate to `lib/config/environment.dart`. The configuration is strictly typed and environment-aware:
   - For debug/local builds, it defaults to `http://localhost:3000`.
   - For production (`--release`), replace the `prodApiUrl` variable with your live server domain (e.g., Railway).

4. **Run the Application:**
   ```bash
   flutter run
   ```

---

## 🤝 Contribution Guidelines
We welcome contributions! Please review our coding standards and ensure that any new features maintain the strict separation of concerns between the mobile client and the execution backend. 

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

Copyright (c) 2026 **B JASWANTH REDDY**. All rights reserved.

See the [LICENSE](LICENSE) file for the full legal text.
