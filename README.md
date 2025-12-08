# Claude Code Skills

Personal collection of Claude Code skills.

## Skills

### beads-workflow

Workflow patterns for [beads](https://github.com/steveyegge/beads) issue tracking:

- Session close protocol (sync and push before claiming done)
- Dependency direction ("needs" not "comes before")
- Core `bd` command reference

## Installation

Add to your Claude Code plugins:

```bash
claude plugins add chrisvaillancourt/claude-code-skills
```

Or clone and symlink:

```bash
git clone https://github.com/chrisvaillancourt/claude-code-skills.git
ln -s /path/to/claude-code-skills ~/.claude/plugins/chris-skills
```

## Usage

Skills are automatically available in Claude Code conversations. Reference them with the Skill tool or they'll be suggested when relevant.
