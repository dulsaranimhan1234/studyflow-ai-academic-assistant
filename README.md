# StudyFlow

**A Flutter academic planner that brings task management and AI-assisted study planning together.**

StudyFlow is a portfolio project for organizing coursework, tracking deadlines, and generating a daily study plan. The mobile app uses Firebase Authentication, sends protected requests through n8n webhooks, stores task data in MySQL, and connects the planner workflow to Gemini.

> This repository contains source code and n8n workflow exports. It does not include a hosted demo or deployment environment; workflow activation and service credentials must be configured locally.

## Project objectives

- Give students one place to manage academic tasks and deadlines.
- Protect task and planner requests with Firebase Authentication.
- Automate task operations and study-plan generation with n8n.
- Keep the app, authentication service, database schema, and workflow definitions understandable as a portfolio project.

## Features

- Register and sign in with Firebase Authentication.
- Create, view, edit, complete, and delete study tasks.
- Track task subject, deadline, priority, status, urgency, and days remaining.
- Generate and view an AI-assisted daily study plan.
- Show user-friendly errors for planner rate limits, temporary service failures, network errors, and timeouts.
- Include mock-based tests for models, API requests, authentication startup, and the planner flow.

## Technology stack

| Area | Technology |
| --- | --- |
| Mobile app | Flutter, Dart |
| Authentication | Firebase Authentication; Firebase Admin SDK for ID-token verification |
| Automation and API orchestration | n8n webhooks and workflows |
| AI planning | Gemini, called by the n8n planner workflow |
| Task persistence | MySQL |
| Auth verification service | Node.js, Express |
| Tests | Flutter test framework, mocked HTTP and Firebase platform interfaces |

## Architecture

```text
┌──────────────────────┐       Firebase sign-in / ID token
│ Flutter mobile app   │ ──────────────────────────────────► Firebase Auth
└──────────┬───────────┘
           │ HTTPS/HTTP webhook request with Bearer ID token
           ▼
┌──────────────────────┐       verify ID token       ┌──────────────────────┐
│ n8n task and planner │ ──────────────────────────► │ Express auth service │
│ workflows            │                              │ Firebase Admin SDK   │
└───────┬────────┬─────┘                              └──────────────────────┘
        │        │
        ▼        ▼
   ┌────────┐  ┌────────┐
   │ MySQL  │  │ Gemini │
   │ tasks  │  │ API    │
   └────────┘  └────────┘
```

The Flutter client obtains a Firebase ID token and sends it in the `Authorization` header. n8n routes task operations to MySQL and handles the planner workflow; the Express service exposes a Firebase Admin-backed `/verify` endpoint for token verification. Gemini is called from the n8n planner workflow. Credentials belong in local Firebase and n8n configuration, not in this README or source control.

## n8n workflow overview

The [`workflows/`](workflows/) directory contains workflow exports for the app’s task and planning flows, including create/get/update/complete/delete operations and the Daily Planner and Scheduled Daily Planner. The exports use webhook, MySQL, HTTP Request, code, and schedule-trigger nodes. Additional exports cover reminders, summaries, task follow-ups, and task insights.

The repository contains workflow definitions, but their presence does not establish that they are imported, active, or publicly reachable. Validate each export before importing it: `StudyFlow - Daily Planner.json` currently fails JSON parsing in this checkout. Configure n8n credentials, webhook URLs, and network access in your own environment.

## Local setup

### Prerequisites

- Flutter SDK compatible with the constraint in [`studyflow_mobile/pubspec.yaml`](studyflow_mobile/pubspec.yaml)
- Node.js and npm
- A Firebase project configured for the Flutter platforms you intend to run
- Local n8n and MySQL instances

### 1. Prepare MySQL and n8n

Create the task database and table from the repository root:

```bash
mysql -u YOUR_MYSQL_USER -p < database/schema.sql
```

Start MySQL and n8n using your local environment. Import the required workflow JSON exports from `workflows/`, then configure the MySQL and Gemini credentials and webhook settings inside n8n.

### 2. Prepare the Firebase token verification service

The auth service expects a Firebase Admin service-account file at `auth-service/firebase-service-account.json`. Obtain it through Firebase project administration, keep it private, and do not add it to Git.

```bash
cd auth-service
npm install
node server.js
```

The service listens on port `3000` and provides `/health` and `/verify` routes. Ensure n8n can reach it on the network used by your local setup.

### 3. Run the Flutter app

Configure Firebase platform settings for your own Firebase project. The app currently defaults to `http://localhost:5678/webhook` in `ApiService`; point this setting at a reachable webhook base URL for your local device or emulator before running.

```bash
cd studyflow_mobile
flutter pub get
flutter run
```

`localhost` refers to the device or emulator running the app, so it may not refer to the computer hosting n8n. Use an appropriate reachable local address for your environment. Use HTTPS for any non-local service.

## Tests and analysis

From `studyflow_mobile/`:

```bash
flutter test
flutter analyze
```

**Verified Phase 9 result:** 29 Flutter tests passed and `flutter analyze` reported no issues. Tests use mocked Firebase and HTTP services; they do not call live Firebase, n8n, or Gemini endpoints.

## Screenshots and demo

<!-- Add sanitized screenshots under docs/screenshots and uncomment/update these examples when files are available.
![Sign-in screen](docs/screenshots/sign-in.png)
![Task dashboard](docs/screenshots/dashboard.png)
![AI study plan](docs/screenshots/study-plan.png)
Demo: add a public demo link only if one is deployed and maintained.
-->

_Screenshots and a public demo link can be added here when available. Do not include account details, tokens, private webhook URLs, or credentials in screenshots._

## Repository layout

```text
auth-service/       Express service for Firebase ID-token verification
database/           MySQL task schema
studyflow_mobile/   Flutter application and tests
workflows/          n8n workflow exports
```
