# NhasixApp Skills

Custom skills for Qwen Code agent to assist with NhasixApp development.

## 📚 Available Skills

### 1. **clean-arch** 
**Path:** `clean-arch/SKILL.md`  
**Purpose:** Clean Architecture guidance and code reviews

**When to use:**
- Setting up new feature architecture
- Reviewing code structure
- Ensuring proper layer separation
- Creating entities, models, repositories, use cases

**Key topics:**
- Layer structure (domain, data, presentation)
- Entity and Model patterns
- Repository pattern
- Use case pattern
- Dependency rules

---

### 2. **bloc-pattern**
**Path:** `bloc-pattern/SKILL.md`  
**Purpose:** BLoC/Cubit state management patterns

**When to use:**
- Creating new cubits/blocs
- Implementing state management
- Testing cubits
- Choosing between Cubit vs BLoC

**Key topics:**
- BaseCubit pattern
- State immutability
- Event handling
- Testing with bloc_test
- Common patterns (loading, pagination, forms)

---

### 3. **di-setup**
**Path:** `di-setup/SKILL.md`  
**Purpose:** Dependency Injection with GetIt setup

**When to use:**
- Registering new dependencies
- Debugging DI issues
- Setting up service locator
- Testing with mocks

**Key topics:**
- Registration order
- LazySingleton vs Singleton vs Factory
- Async initialization
- Circular dependency resolution
- Testing with DI

---

### 4. **project-workflow**
**Path:** `project-workflow/SKILL.md`  
**Purpose:** Development workflow phases and processes

**When to use:**
- Starting new feature development
- Following project rules
- Creating analysis/plan documents
- Managing git workflow

**Key topics:**
- Analysis → Planning → Execution → Completion
- File structure and naming
- Git workflow and commits
- Quality gates
- Release process

---

## 🎯 How to Use Skills

### Invoke a Skill

Use the `skill` tool with the skill name:

```
skill: "clean-arch"      # For architecture guidance
skill: "bloc-pattern"    # For state management help
skill: "di-setup"        # For DI configuration
skill: "project-workflow" # For workflow questions
```

### When Skills Load Automatically

Skills provide context to Qwen Code agent automatically when:
- Discussing architecture → `clean-arch`
- Creating state management → `bloc-pattern`
- Setting up dependencies → `di-setup`
- Following workflow → `project-workflow`

---

## 📋 Skill Template

Each skill follows this structure:

```markdown
# Skill Name

## 📚 Overview
What this skill covers

## 🏗️ Core Concepts
Key principles and patterns

## 📝 Examples
Code examples and templates

## ✅ Best Practices
DO and DON'T guidelines

## 🧪 Testing
How to test implementations

## 📚 References
Links to documentation
```

---

## 🔄 Updating Skills

To update a skill:

1. Edit the `SKILL.md` file in the skill's directory
2. Update the version/date if applicable
3. Test the skill by invoking it
4. Document changes in this README

---

## 📊 Skill Usage Examples

### Example 1: Creating New Feature

```
1. Invoke: skill: "project-workflow"
   → Follow analysis → planning → execution workflow

2. Invoke: skill: "clean-arch"
   → Set up proper layer structure

3. Invoke: skill: "bloc-pattern"
   → Create cubits for state management

4. Invoke: skill: "di-setup"
   → Register new dependencies in GetIt
```

### Example 2: Code Review

```
1. Invoke: skill: "clean-arch"
   → Check architecture compliance

2. Invoke: skill: "bloc-pattern"
   → Review state management

3. Invoke: skill: "project-workflow"
   → Ensure proper git workflow followed
```

---

## 🎓 Learning Resources

- [Qwen Code Skills Documentation](https://github.com/QwenLM/qwen-code)
- [Flutter Best Practices](https://docs.flutter.dev/guides)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [BLoC Library](https://bloclibrary.dev/)
- [GetIt Package](https://pub.dev/packages/get_it)

---

**Last Updated:** March 12, 2026  
**Version:** 1.0.0
