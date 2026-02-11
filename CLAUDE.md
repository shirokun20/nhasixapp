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

#### 🧭 Active Steering (Automatic Context)
**CRITICAL**: At the start of every session, YOU MUST:
1.  Check `projects/onprogress-plan/`.
2.  If a project exists there, READ its `progress.md` and main Spec file immediately.
3.  **Treat `progress.md` as the Master Plan**. Do not implement features not listed there.
4.  **Update `progress.md`** automatically as tasks are completed.

#### Phases:

1.  **Analysis & Planning**
    *   **Folder Structure**: `projects/analysis-plan/[project_name]/`
    *   **Main File**: `[project_name]_[date].md` (Copy from `projects/templates/project_plan_template.md`)
    *   **Issues**: `projects/issues/` (Markdown files allowed here)
    *   **Backlog**: `projects/future-plan/[project_name]/` (Follows Analysis structure)
    **STOP & WAIT**: Do not move ANY of these to Execution without explicit user command.

2.  **Execution** (`projects/onprogress-plan/`)
    *   **Convert Issue to Folder**: Create folder `[project_name]`. Move issue to `resolved_issues/`.
    *   **Main File**: Ensure `[project_name]_[date].md` exists.
    *   **Require `progress.md`**: MUST exist for dashboard tracking (Copy Implementation Plan from Analysis).
    *   **Approval**: Only move here after explicit user approval.

3.  **Completion** (`projects/success-plan/`)
    *   **Move Folder**: Move the entire folder here.
    *   **Update**: Mark `progress.md` as 100%.
    *   **Script**: Run `dart scripts/project_status.dart`.
    *   **Git**: DO NOT run `git add/commit`. User handles source control.

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
