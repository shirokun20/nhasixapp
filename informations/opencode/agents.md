# Agents

Configure and use specialized agents.

Agents are specialized AI assistants that can be configured for specific tasks and workflows. They allow you to create focused tools with custom prompts, models, and tool access.

> **Tip**: Use the plan agent to analyze code and review suggestions without making any code changes.

You can switch between agents during a session or invoke them with the `@` mention.

---

## Types

There are two types of agents in OpenCode: primary agents and subagents.

### Primary agents

Primary agents are the main assistants you interact with directly. You can cycle through them using the **Tab** key, or your configured `switch_agent` keybind. These agents handle your main conversation. Tool access is configured via permissions — for example, Build has all tools enabled while Plan is restricted.

> **Tip**: You can use the **Tab** key to switch between primary agents during a session.

OpenCode comes with two built-in primary agents, **Build** and **Plan**.

### Subagents

Subagents are specialized assistants that primary agents can invoke for specific tasks. You can also manually invoke them by **@ mentioning** them in your messages.

OpenCode comes with two built-in subagents, **General** and **Explore**.

---

## Built-in

OpenCode comes with two built-in primary agents and two built-in subagents.

### Use build

*Mode*: `primary`

Build is the **default** primary agent with all tools enabled. This is the standard agent for development work where you need full access to file operations and system commands.

### Use plan

*Mode*: `primary`

A restricted agent designed for planning and analysis. We use a permission system to give you more control and prevent unintended changes. By default, all of the following are set to `ask`:

- `file edits`: All writes, patches, and edits
- `bash`: All bash commands

This agent is useful when you want the LLM to analyze code, suggest changes, or create plans without making any actual modifications to your codebase.

### Use general

*Mode*: `subagent`

A general-purpose agent for researching complex questions and executing multi-step tasks. Has full tool access (except todo), so it can make file changes when needed. Use this to run multiple units of work in parallel.

### Use explore

*Mode*: `subagent`

A fast, read-only agent for exploring codebases. Cannot modify files. Use this when you need to quickly find files by patterns, search code for keywords, or answer questions about the codebase.

### Use compaction

*Mode*: `primary`

Hidden system agent that compacts long context into a smaller summary. It runs automatically when needed and is not selectable in the UI.

### Use title

*Mode*: `primary`

Hidden system agent that generates short session titles. It runs automatically and is not selectable in the UI.

### Use summary

*Mode*: `primary`

Hidden system agent that creates session summaries. It runs automatically and is not selectable in the UI.

---

## Usage

1. **For primary agents**, use the **Tab** key to cycle through them during a session. You can also use your configured `switch_agent` keybind.

2. **Subagents** can be invoked:
   - **Automatically** by primary agents for specialized tasks based on their descriptions.
   - **Manually** by **@ mentioning** a subagent in your message. For example:
     ```
     @general help me search for this function
     ```

3. **Navigation between sessions**: When subagents create their own child sessions, you can navigate between the parent session and all child sessions using:
   - **<Leader>+Right** (or your configured `session_child_cycle` keybind) to cycle forward through parent → child1 → child2 → … → parent
   - **<Leader>+Left** (or your configured `session_child_cycle_reverse` keybind) to cycle backward through parent ← child1 ← child2 ← … ← parent

---

## Configure

You can customize the built-in agents or create your own through configuration. Agents can be configured in two ways:

### JSON

Configure agents in your `opencode.json` config file:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "build": {
      "mode": "primary",
      "model": "anthropic/claude-sonnet-4-20250514",
      "prompt": "{file:./prompts/build.txt}",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true
      }
    },
    "plan": {
      "mode": "primary",
      "model": "anthropic/claude-haiku-4-20250514",
      "tools": {
        "write": false,
        "edit": false,
        "bash": false
      }
    },
    "code-reviewer": {
      "description": "Reviews code for best practices and potential issues",
      "mode": "subagent",
      "model": "anthropic/claude-sonnet-4-20250514",
      "prompt": "You are a code reviewer. Focus on security, performance, and maintainability.",
      "tools": {
        "write": false,
        "edit": false
      }
    }
  }
}
```

### Markdown

You can also define agents using markdown files. Place them in:

- **Global**: `~/.config/opencode/agents/`
- **Per-project**: `.opencode/agents/`

Example `~/.config/opencode/agents/review.md`:

```yaml
---
description: Reviews code for quality and best practices
mode: subagent
model: anthropic/claude-sonnet-4-20250514
temperature: 0.1
tools:
  write: false
  edit: false
  bash: false
---

You are in code review mode. Focus on:
- Code quality and best practices
- Potential bugs and edge cases
- Performance implications
- Security considerations

Provide constructive feedback without making direct changes.
```

The markdown file name becomes the agent name. For example, `review.md` creates a `review` agent.

---

## Options

### Description

Use the `description` option to provide a brief description of what the agent does and when to use it.

```json
{
  "agent": {
    "review": {
      "description": "Reviews code for best practices and potential issues"
    }
  }
}
```

This is a **required** config option.

### Temperature

Control the randomness and creativity of the LLM's responses with the `temperature` config.

Lower values make responses more focused and deterministic, while higher values increase creativity and variability.

Temperature values typically range from 0.0 to 1.0:

- **0.0-0.2**: Very focused and deterministic responses, ideal for code analysis and planning
- **0.3-0.5**: Balanced responses with some creativity, good for general development tasks
- **0.6-1.0**: More creative and varied responses, useful for brainstorming and exploration

```json
{
  "agent": {
    "analyze": {
      "temperature": 0.1,
      "prompt": "{file:./prompts/analysis.txt}"
    },
    "build": {
      "temperature": 0.3
    },
    "brainstorm": {
      "temperature": 0.7,
      "prompt": "{file:./prompts/creative.txt}"
    }
  }
}
```

If no temperature is specified, OpenCode uses model-specific defaults; typically 0 for most models, 0.55 for Qwen models.

### Max steps

Control the maximum number of agentic iterations an agent can perform before being forced to respond with text only.

```json
{
  "agent": {
    "quick-thinker": {
      "description": "Fast reasoning with limited iterations",
      "prompt": "You are a quick thinker. Solve problems with minimal steps.",
      "steps": 5
    }
  }
}
```

When the limit is reached, the agent receives a special system prompt instructing it to respond with a summarization of its work and recommended remaining tasks.

> **Caution**: The legacy `maxSteps` field is deprecated. Use `steps` instead.

### Disable

Set to `true` to disable the agent.

```json
{
  "agent": {
    "review": {
      "disable": true
    }
  }
}
```

### Prompt

Specify a custom system prompt file for this agent with the `prompt` config.

```json
{
  "agent": {
    "review": {
      "prompt": "{file:./prompts/code-review.txt}"
    }
  }
}
```

### Model

Use the `model` config to override the model for this agent.

```json
{
  "agent": {
    "plan": {
      "model": "anthropic/claude-haiku-4-20250514"
    }
  }
}
```

The model ID in your OpenCode config uses the format `provider/model-id`.

### Tools

Control which tools are available in this agent with the `tools` config.

```json
{
  "$schema": "https://opencode.ai/config.json",
  "tools": {
    "write": true,
    "bash": true
  },
  "agent": {
    "plan": {
      "tools": {
        "write": false,
        "bash": false
      }
    }
  }
}
```

You can also use wildcards to control multiple tools at once:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "readonly": {
      "tools": {
        "mymcp_*": false,
        "write": false,
        "edit": false
      }
    }
  }
}
```

### Permissions

Configure permissions to manage what actions an agent can take.

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "edit": "deny"
  }
}
```

You can override these permissions per agent:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "edit": "deny"
  },
  "agent": {
    "build": {
      "permission": {
        "edit": "ask"
      }
    }
  }
}
```

You can set permissions for specific bash commands:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "build": {
      "permission": {
        "bash": {
          "git push": "ask",
          "grep *": "allow"
        }
      }
    }
  }
}
```

### Mode

Control the agent's mode with the `mode` config. Options: `primary`, `subagent`, or `all`.

```json
{
  "agent": {
    "review": {
      "mode": "subagent"
    }
  }
}
```

### Hidden

Hide a subagent from the `@` autocomplete menu with `hidden: true`.

```json
{
  "agent": {
    "internal-helper": {
      "mode": "subagent",
      "hidden": true
    }
  }
}
```

### Task permissions

Control which subagents an agent can invoke via the Task tool with `permission.task`.

```json
{
  "agent": {
    "orchestrator": {
      "mode": "primary",
      "permission": {
        "task": {
          "*": "deny",
          "orchestrator-*": "allow",
          "code-reviewer": "ask"
        }
      }
    }
  }
}
```

Rules are evaluated in order, and the **last matching rule wins**.

### Color

Customize the agent's visual appearance in the UI.

```json
{
  "agent": {
    "creative": {
      "color": "#ff6b6b"
    },
    "code-reviewer": {
      "color": "accent"
    }
  }
}
```

Use a valid hex color (e.g., `#FF5733`) or theme color: `primary`, `secondary`, `accent`, `success`, `warning`, `error`, `info`.

### Top P

Control response diversity with the `top_p` option.

```json
{
  "agent": {
    "brainstorm": {
      "top_p": 0.9
    }
  }
}
```

Values range from 0.0 to 1.0. Lower values are more focused, higher values more diverse.

### Additional

Any other options you specify will be **passed through directly** to the provider as model options.

```json
{
  "agent": {
    "deep-thinker": {
      "description": "Agent that uses high reasoning effort for complex problems",
      "model": "openai/gpt-5",
      "reasoningEffort": "high",
      "textVerbosity": "low"
    }
  }
}
```

---

## Create agents

You can create new agents using the following command:

```bash
opencode agent create
```

This interactive command will:
1. Ask where to save the agent; global or project-specific.
2. Description of what the agent should do.
3. Generate an appropriate system prompt and identifier.
4. Let you select which tools the agent can access.
5. Finally, create a markdown file with the agent configuration.

---

## Use cases

- **Build agent**: Full development work with all tools enabled
- **Plan agent**: Analysis and planning without making changes
- **Review agent**: Code review with read-only access plus documentation tools
- **Debug agent**: Focused on investigation with bash and read tools enabled
- **Docs agent**: Documentation writing with file operations but no system commands

---

## Examples

### Documentation agent

```markdown
---
description: Writes and maintains project documentation
mode: subagent
tools:
  bash: false
---

You are a technical writer. Create clear, comprehensive documentation.
Focus on:
- Clear explanations
- Proper structure
- Code examples
- User-friendly language
```

### Security auditor

```markdown
---
description: Performs security audits and identifies vulnerabilities
mode: subagent
tools:
  write: false
  edit: false
---

You are a security expert. Focus on identifying potential security issues.
Look for:
- Input validation vulnerabilities
- Authentication and authorization flaws
- Data exposure risks
- Dependency vulnerabilities
- Configuration security issues
```

---

*Source: https://opencode.ai/docs/agents/*
*Last updated: Feb 15, 2026*
