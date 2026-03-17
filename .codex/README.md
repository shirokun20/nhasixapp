# Codex Project Adapter

This repository already maintains its workflow, rules, agents, and skills for multiple AI tools. Codex must reuse those existing assets instead of introducing a separate process.

## Source Of Truth

1. `AGENTS.md`
2. `project_memory.md`
3. Active file in `projects/onprogress-plan/*/progress.md`
4. Active main spec in the same project folder

## Local Rule Sources

- Primary: `AGENTS.md`
- Mirror rules: `.github/copilot-instructions.md`
- Secondary rules: `.agent/rules/asix-rules.md`

If rules overlap, follow the stricter local project rule.

## Local Skill Sources

- Project-local Codex skills: `.codex/skills/[skill]/SKILL.md`
- Upstream primary skills: `.opencode/skills/[skill]/SKILL.md`
- Secondary skills: `.agent/skills/[skill]/SKILL.md`

When a task clearly matches one of these skills, read the relevant `SKILL.md` before implementation.

## Scope

These skills are intentionally copied into `.codex/skills/` for this repository only.
Do not treat `~/.codex/skills` as the install target for project-specific behavior unless the user explicitly asks for a global install.

## Role Mapping For Codex

Codex should treat local `@agent` names as execution roles to emulate directly:

- `@planner`: analysis and implementation planning
- `@architect`: Clean Architecture review
- `@flutter-architect`: Flutter architecture guidance
- `@feature-dev`: execution coordination
- `@code-reviewer`: defect-focused review
- `@ui-designer`: UI/UX review
- `@test-engineer` and `@test-writer`: test design and implementation

Use explicit sub-agent delegation only when the user asks for delegation or parallel agents.

## Operating Rules

- Follow the project lifecycle in `projects/`: analysis -> future -> onprogress -> success.
- Treat `progress.md` as the master execution checklist for active work.
- Do not implement features outside the active plan without explicit user approval.
- Update `project_memory.md` after each session.
- Never edit generated Dart files directly: `*.g.dart`, `*.freezed.dart`.
- Use `rg`, `ugrep`, and `semgrep` instead of basic `grep`.
