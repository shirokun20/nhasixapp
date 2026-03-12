# NhasixApp Agents

Custom Qwen Code agents for specialized assistance with Flutter development.

---

## 🤖 Available Agents

Invoke agents using `@` symbol in your conversation:

### 1. **@flutter-architect**
**Specialization:** Clean Architecture & Code Structure  
**When to use:**
- Designing new feature architecture
- Reviewing code structure
- Ensuring proper layer separation
- Creating entities, models, repositories
- Setting up dependency injection

**Example:**
```
@flutter-architect How should I structure a new search feature?
```

---

### 2. **@feature-dev**
**Specialization:** Development Workflow & Task Management  
**When to use:**
- Starting new feature development
- Breaking down complex tasks
- Following project workflow
- Tracking progress
- Unblocking development issues

**Example:**
```
@feature-dev Help me break down the DNS health monitor feature
```

---

### 3. **@code-reviewer**
**Specialization:** Code Quality & Best Practices  
**When to use:**
- Before committing code
- After completing a feature
- Checking for bugs and issues
- Ensuring architecture compliance
- Performance optimization review

**Example:**
```
@code-reviewer Please review my changes in lib/services/
```

---

### 4. **@ui-designer**
**Specialization:** UI/UX & Responsive Design  
**When to use:**
- Designing new screens
- Improving UI polish
- Making layouts responsive
- Adding animations
- Enhancing accessibility

**Example:**
```
@ui-designer How can I make this list screen more polished?
```

---

## 📁 Agent Files Structure

```
.qwen/agents/
├── README.md                      # This file
├── flutter-architect/
│   └── AGENT.md                  # Architecture agent definition
├── feature-dev/
│   └── AGENT.md                  # Feature development agent
├── code-reviewer/
│   └── AGENT.md                  # Code review agent
└── ui-designer/
    └── AGENT.md                  # UI/UX design agent
```

---

## 🎯 How to Use Agents

### Method 1: Direct Mention

Simply mention the agent in your conversation:

```
@flutter-architect I need help designing the architecture for a new feature...
```

### Method 2: Task Tool

Use the task tool to delegate complex work:

```
task:
  description: "Design DNS feature architecture"
  subagent_type: "general-purpose"
  prompt: "@flutter-architect Review the current DNS implementation and..."
```

### Method 3: Skill + Agent Combo

Combine skills with agents for specialized knowledge:

```
# Load relevant skill
skill: "clean-arch"

# Then ask agent
@flutter-architect Based on the clean architecture patterns...
```

---

## 🔄 Agent vs Skill

**Skills** (`.qwen/skills/`):
- 📚 Reference documentation
- 📖 Loaded via `skill` tool
- 🎯 Provides knowledge base
- 📝 Examples: `clean-arch`, `bloc-pattern`, `di-setup`

**Agents** (`.qwen/agents/`):
- 🤖 Specialized AI personas
- @ Invoked with `@` mention
- 🎭 Specific role/expertise
- 📝 Examples: `@flutter-architect`, `@code-reviewer`

**Use Together:**
```
skill: "clean-arch"        # Load architecture knowledge
@flutter-architect         # Activate architect persona
Now review my code structure
```

---

## 📋 Agent Capabilities

### @flutter-architect

**Can:**
- ✅ Review code architecture
- ✅ Suggest proper patterns
- ✅ Identify layer violations
- ✅ Design feature structure
- ✅ Plan DI registration

**Cannot:**
- ❌ Write implementation code
- ❌ Make business decisions
- ❌ Skip analysis phase

---

### @feature-dev

**Can:**
- ✅ Break down features into tasks
- ✅ Guide through workflow phases
- ✅ Track progress
- ✅ Unblock development issues
- ✅ Suggest next steps

**Cannot:**
- ❌ Write code for you
- ❌ Skip required phases
- ❌ Make architectural decisions

---

### @code-reviewer

**Can:**
- ✅ Review code quality
- ✅ Identify bugs and issues
- ✅ Check architecture compliance
- ✅ Suggest improvements
- ✅ Verify testing coverage

**Cannot:**
- ❌ Approve merges (final decision is yours)
- ❌ Skip critical fixes
- ❌ Ignore security issues

---

### @ui-designer

**Can:**
- ✅ Design UI components
- ✅ Suggest animations
- ✅ Improve accessibility
- ✅ Make layouts responsive
- ✅ Add polish and polish

**Cannot:**
- ❌ Create image assets
- ❌ Skip accessibility requirements
- ❌ Ignore performance

---

## 🎓 Best Practices

### Getting Best Results

**Be Specific:**
```
❌ "Review my code"
✅ "@code-reviewer Please review lib/services/license_service.dart for architecture violations"
```

**Provide Context:**
```
❌ "How do I build this?"
✅ "@flutter-architect I'm adding a search feature with filters. Following clean architecture, what layers do I need?"
```

**Use Phases:**
```
❌ Jump straight to code
✅ "@feature-dev Let's start with analysis phase for the DNS health feature"
```

### When to Use Which Agent

| Task | Primary Agent | Supporting Skill |
|------|---------------|------------------|
| New feature structure | @flutter-architect | clean-arch |
| Task breakdown | @feature-dev | project-workflow |
| Before commit | @code-reviewer | All skills |
| UI polish | @ui-designer | bloc-pattern |
| DI setup | @flutter-architect | di-setup |
| State management | @flutter-architect | bloc-pattern |

---

## 🚀 Example Workflows

### Workflow 1: New Feature

```
1. @feature-dev "Help me plan the DNS health monitor feature"
   → Creates analysis → planning → execution plan

2. @flutter-architect "Design the architecture for DNS health monitor"
   → Provides layer structure, patterns, DI setup

3. skill: "bloc-pattern"
   → Loads BLoC patterns for state management

4. Implement with guidance from @feature-dev

5. @code-reviewer "Review my DNS health implementation"
   → Checks quality, architecture, tests
```

### Workflow 2: Code Review

```
1. @code-reviewer "Review my changes before commit"
   → Comprehensive review

2. Fix issues identified

3. @flutter-architect "Verify architecture compliance"
   → Final architecture check

4. Commit
```

### Workflow 3: UI Enhancement

```
1. @ui-designer "Make this screen more polished"
   → UI/UX suggestions

2. Implement suggestions

3. @ui-designer "Review the updated UI"
   → Final polish check
```

---

## 📊 Agent Status

| Agent | Status | Version | Last Updated |
|-------|--------|---------|--------------|
| @flutter-architect | ✅ Active | 1.0.0 | March 12, 2026 |
| @feature-dev | ✅ Active | 1.0.0 | March 12, 2026 |
| @code-reviewer | ✅ Active | 1.0.0 | March 12, 2026 |
| @ui-designer | ✅ Active | 1.0.0 | March 12, 2026 |

---

## 🔧 Updating Agents

To update an agent:

1. Edit the `AGENT.md` file in the agent's directory
2. Update version and date
3. Test the agent behavior
4. Document changes here

---

## 📚 Related Documentation

- **Skills:** `.qwen/skills/README.md`
- **Workflow:** `.qwen/skills/project-workflow/SKILL.md`
- **Project Rules:** `AGENTS.md`
- **Architecture:** `.qwen/skills/clean-arch/SKILL.md`

---

**Last Updated:** March 12, 2026  
**Version:** 1.0.0
