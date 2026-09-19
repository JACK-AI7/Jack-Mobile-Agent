# 📱 Jack Mobile Agent

![Jack Mobile Agent](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Socket.io](https://img.shields.io/badge/Socket.io-010101?&style=for-the-badge&logo=Socket.io&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

**Jack Mobile Agent** is a next-generation, autonomous AI mobile interface built with Flutter. It connects to a powerful NestJS + BullMQ + Groq backend to execute complex, multi-step tasks natively on your device.

Featuring a fluid, premium "Liquid Orb" interface, Jack provides real-time visual feedback of the AI's internal state (Thinking, Planning, Executing) seamlessly synchronized via WebSockets.

---

## ✨ Features

- 🧠 **Autonomous Task Execution:** Converts natural language into actionable, multi-step device commands.
- ⚡ **Real-Time WebSocket Sync:** Powered by Socket.IO to stream execution states instantly from the backend worker.
- 🎨 **Premium UI/UX:** Features a dynamic, glowing "Orb" visualizer that reacts to the agent's live lifecycle states.
- 🔒 **Secure Authentication:** JWT-based auth flow utilizing `flutter_secure_storage` for protected routes and tenant isolation.
- 🛠️ **Extensible Tool Registry:** Modular "Capsule" architecture for injecting new capabilities (e.g., App Launching, Settings Control, Media).
- 🚀 **Environment Aware:** Seamlessly switches between local Docker development and production deployment (e.g., Railway).

---

## 🏗️ Architecture

Jack Mobile Agent acts as the presentation and execution layer of a broader distributed system. 

1. **User Request:** The user submits a prompt via the Flutter app.
2. **REST API (`jack-api`):** The app authenticates and POSTs the task to the NestJS backend.
3. **Queue (`BullMQ`):** The backend enqueues the task in a Redis-backed queue.
4. **Processing (`jack-worker`):** A background worker pulls the task, interfaces with the Groq AI provider, and maps out a tool execution plan.
5. **Real-time Sync (`Socket.IO`):** The worker emits state changes (`QUEUED` → `PLANNING` → `RUNNING` → `SUCCESS`) which the Flutter app listens to and reflects visually via the Jack Orb.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable)
- [Dart SDK](https://dart.dev/get-dart)
- A running instance of the **Jack Backend** (NestJS + Postgres + Redis)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/JACK-AI7/Jack-Mobile-Agent.git
   cd Jack-Mobile-Agent
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment:**
   Ensure your API URL is correctly set in `lib/config/environment.dart`. 
   By default, it uses `http://localhost:3000` for debug builds and your production URL for release builds.

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 🔐 Security & Privacy

Jack is built with security first.
- **No Hardcoded Secrets:** All AI Provider API keys (Groq, OpenAI, etc.) are strictly kept on the backend server.
- **Encrypted Storage:** JWT tokens are stored securely in the device's keychain/keystore.
- **Execution Guardrails:** Tool execution requires explicit modeling and sandboxing.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2026. All rights reserved.
