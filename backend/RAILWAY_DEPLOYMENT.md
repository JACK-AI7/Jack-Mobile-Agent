# Railway Deployment Guide for JACK AGENT

This guide explains how to properly deploy the Jack Agent architecture on Railway. The backend architecture consists of an HTTP API (with WebSocket) and a separate BullMQ Worker. They use the exact same Docker image/source repository but execute different entry points.

## 1. Create the Railway Project
1. Log into your [Railway Dashboard](https://railway.app/).
2. Create a new **Empty Project**.

## 2. Provision Managed Infrastructure
From your new project dashboard:
1. Click **New** -> **Database** -> **Add PostgreSQL**.
2. Click **New** -> **Database** -> **Add Redis**.

Railway will automatically manage these, ensuring they are not public on the internet.

## 3. Deploy the API Service (`jack-api`)
1. Click **New** -> **GitHub Repo** (or via CLI `railway up`).
2. Select your `jack-backend` repository folder.
3. Once created, rename the service to **`jack-api`**.
4. **Environment Variables**:
   * `PORT`: `3000` (or Railway will inject it).
   * `DATABASE_URL`: `${Postgres.DATABASE_URL}` (Reference the Postgres variable)
   * `REDIS_URL`: `${Redis.REDIS_URL}` (Reference the Redis variable)
   * `JWT_SECRET`: Generate a secure random string (e.g., `openssl rand -hex 32`)
   * `GROQ_API_KEY`: Your real Groq API key
   * `CORS_ORIGINS`: `https://your-flutter-app.domain.com` (Add your frontend's production origin; skip if building a pure native mobile app)
   * `RUN_MODE`: `API`
5. **Settings -> Build / Deploy**:
   * Root Directory: `.` (or `/` depending on your repo structure).
   * Install Command: `pnpm install`
   * Build Command: `pnpm build`
   * Start Command: `pnpm run start:api`
6. **Generate Public Domain**:
   * Under Settings -> Networking, click **Generate Domain** (e.g., `jack-api-production.up.railway.app`).

## 4. Deploy the Worker Service (`jack-worker`)
1. In the same project dashboard, click **New** -> **GitHub Repo** again.
2. Select the *exact same repository*.
3. Rename this second service to **`jack-worker`**.
4. **Environment Variables**:
   * `DATABASE_URL`: `${Postgres.DATABASE_URL}`
   * `REDIS_URL`: `${Redis.REDIS_URL}`
   * `GROQ_API_KEY`: Your real Groq API key (used heavily here by the AgentRuntime)
   * `RUN_MODE`: `WORKER`
5. **Settings -> Build / Deploy**:
   * Install Command: `pnpm install`
   * Build Command: `pnpm build`
   * Start Command: `pnpm run start:worker`
6. **IMPORTANT**: Do *not* generate a public domain for this service. It should remain strictly private.

## 5. Configure the Database Schema (Pre-deploy)
The `User` table needs the new `passwordHash` field.
When deploying the `jack-api` service, Railway might not run Prisma migrations by default. You have a few options:
* **Option A**: Run `pnpm prisma migrate deploy` locally connected to your Railway Postgres database (using the external connection string).
* **Option B**: Add a `prebuild` or `prestart` script in `package.json` to execute `npx prisma migrate deploy`.

*Warning: NEVER use `prisma migrate reset` or `prisma db push` on production.*

## 6. Configure Flutter App for Production
Open your Flutter repository (`jack-mobile-agent`).
1. Navigate to `lib/config/environment.dart`.
2. Update the `prodApiUrl` variable with the exact public domain generated for your `jack-api` service (e.g., `https://jack-api-production.up.railway.app`).
3. Build for your target platforms using `--release` to ensure `isProduction` evaluates to true.

## 7. Verification Steps
Once both services are "Active":
1. **Health Check**: Open `https://<api-domain>/health` in your browser. You should see `{"status":"ok", "database":"connected"}`.
2. **Authentication**: In the Flutter app, try creating a new account.
3. **Execution**: Ask the Agent a question. The `jack-api` will write to Postgres and enqueue a Redis job.
4. **Worker**: Check the Logs for the `jack-worker` service in Railway. You should see `[AgentExecutionProcessor] Processing job...` and `[GroqProvider] Routing to GROQ...`.
5. **WebSocket**: The Flutter UI should automatically progress from "THINKING" -> "EXECUTING" -> "SUCCESS".
