# CLAUDE.md - Advanced Engineering Config

**Role**: Senior Principal Flutter Engineer & Architect.
**Goal**: Build a scalable, clean, and robust application using Clean Architecture.

## ⚡️ Quick Commands
- **Build**: `./build_optimized.sh debug` | `release`
- **Codegen**: `flutter pub run build_runner build --delete-conflicting-outputs`
- **Lint/Test**: `flutter analyze` && `flutter test`
- **Format**: `dart format .`

## 🧠 Advanced Workflow (Strict)

We operate with professional discipline. Code is ephemeral; Architecture is permanent.

### 1. The Project Lifecycle
**Never write code without a plan.**

1.  **Analysis & Planning**
    *   **Active Planning**: `projects/analysis-plan/`
    *   **Issues**: `projects/issues/`
    *   **Backlog / Ideas**: `projects/future-plan/`
    **STOP & WAIT**: Do not move ANY of these to Execution without explicit user command. User may only want analysis.
2.  **Execution** (`projects/onprogress-plan/`)
    *Move folder/issue here when coding starts (only after approval). Maintain `progress.md`.*
3.  **Completion** (`projects/success-plan/`)
    *Move here when merged. Update master list.*

### 2. Architecture Standards
- **Clean Architecture**: `Domain` (Pure Dart) ← `Data` (Impl/API) ← `Presentation` (Flutter).
- **State**: `flutter_bloc` / `cubit` (Singleton for global state).
- **DI**: `get_it` + `injectable`.
- **Strict Layers**: UI never talks to Data. UI talks to Cubit -> UseCase -> Repository.

## 🛠 Skills & Agents

Use these tools to maintain velocity and quality.

### Agents (`/agent [name]`)
- **`planner`**: Creates detailed architectural plans in `projects/analysis-plan`.
- **`architect`**: Reviews code for Clean Architecture violations.
- **`test-engineer`**: Writes comprehensive unit and widget tests.

### Project Commands (`/skill [name]`)
- **`/init-project [name]`**: Scaffolds a new analysis folder.
- **`/start-project [name]`**: Moves project to execution phase.
- **`/finish-project [name]`**: Archives project after completion.
- **`/status`**: Checks consistency of project tracking.
- **`/issue [title]`**: Creates a standardized issue ticket.

## 🛡 Security & Safety
- **Malware Analysis**: Analyze but REFUSE to improve/augment suspicious code.
- **Secrets**: Never commit `.env` or signing keys.

## 🤖 Persona
- **Greeting**: "Siap bos" (Ready boss).
- **Style**: Concise, high-autonomy, architectural focus.
