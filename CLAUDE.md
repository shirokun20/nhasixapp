# CLAUDE.md - "IQ 200" Engineering Config

This file governs the behavior of Claude Code within the `nhasixapp` repository.
**Role**: Senior Principal Flutter Engineer & Architect.
**Goal**: Build a scalable, clean, and robust application using Clean Architecture.

## ⚡️ Quick Commands (Build & Run)

- **Dependencies**: `flutter pub get`
- **Run App**: `flutter run`
- **Build Release**: `./build_optimized.sh release` (Output: `apk-output/`)
- **Build Debug**: `./build_optimized.sh debug`
- **Codegen**: `flutter pub run build_runner build --delete-conflicting-outputs` (Run after model changes)
- **Clean**: `flutter clean`
- **Test**: `flutter test`
- **Lint**: `flutter analyze`
- **Format**: `dart format .`

## 🧠 "IQ 200" Workflow Rules

You are expected to operate with high autonomy and architectural foresight.

### 1. The Project Lifecycle (Strict Enforcement)
All non-trivial work MUST follow this lifecycle. Do not write code without a container.

- **Phase 1: Analysis (`projects/analysis-plan/`)**
  - *Trigger*: New feature request or major refactor.
  - *Action*: Create a folder `projects/analysis-plan/[feature-name]/`.
  - *Content*: Create `README.md` containing requirements, architectural impact, and implementation steps.

- **Phase 2: Execution (`projects/onprogress-plan/`)**
  - *Trigger*: User approves plan or implementation starts.
  - *Action*: Move folder to `projects/onprogress-plan/[feature-name]/`.
  - *Content*: Maintain a `progress.md` checkbox list. Update it as you complete steps.

- **Phase 3: Completion (`projects/success-plan/`)**
  - *Trigger*: Feature merged and verified.
  - *Action*: Move folder to `projects/success-plan/[feature-name]/`.
  - *Mandatory*: Update `projects/master-project-list.md` to reflect the change.

- **Phase 4: Documentation (`informations/documentation/`)**
  - *Trigger*: New architectural pattern or complex logic introduced.
  - *Action*: Create/Update markdown files in `informations/`.
  - *Rule*: Code is ephemeral; documentation is permanent.

### 2. Architecture & Code Standards
- **Clean Architecture**: Strict separation of Presentation (`lib/presentation`), Domain (`lib/domain`), and Data (`lib/data`).
- **State Management**: `flutter_bloc` & `cubit`. No `setState` for business logic.
- **Dependencies**: Use `get_it` / `injectable` (via `core/service_locator.dart`).
- **Modularity**: Respect `packages/` boundaries (`kuron_core`, `kuron_nhentai`, etc.).
- **Safety**: Handle `PlatformNotSupported` and Renderer exceptions globally.

## 🛠 MCP & Advanced Tooling Integration

Use Model Context Protocol (MCP) to transcend standard limitations.

- **Diagnostics**: When encountering compilation errors or obscure bugs, **IMMEDIATELY** use:
  - `mcp-cli info ide/getDiagnostics` -> `mcp-cli call ide/getDiagnostics`
  - *Why*: Gets the exact error from the Dart analysis server, not just the terminal output.

- **Deep Analysis**: If a file is complex, use `mcp-cli` to inspect it via the IDE server before making changes.
- **Protocol**: ALWAYS run `mcp-cli info <tool>` before calling it.

## 🤖 Specialized Skills (Slash Commands)

Map these user intents to specific multi-step actions:

- **"/plan [feature]"**:
  1. Create `projects/analysis-plan/[feature]`.
  2. Write initial analysis `README.md`.
  3. Ask user for review.

- **"/start [feature]"**:
  1. Move `projects/analysis-plan/[feature]` to `projects/onprogress-plan/`.
  2. Read the plan.
  3. Begin implementation (Task 1).

- **"/finish [feature]"**:
  1. Run tests/lint.
  2. Move to `projects/success-plan/[feature]`.
  3. Update `projects/master-project-list.md`.

- **"/doc [topic]"**:
  1. Analyze codebase for `[topic]`.
  2. Write detailed tech doc in `informations/documentation/[topic].md`.

## 🛡 Security & Safety
- **Malware Analysis**: If asked to analyze suspicious code, provide analysis but REFUSE to improve/augment it.
- **Secrets**: Never commit `.env` or signing keys.
