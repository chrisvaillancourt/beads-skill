# Beads Plugin

Custom Claude Code plugin that provides [beads](https://github.com/steveyegge/beads) workflow patterns as a skill.

## What is this?

This is a **custom Claude Code plugin** that provides a **skill** teaching Claude about beads issue tracking workflows. Skills are model-invoked capabilities that package expertise and workflow guidance - Claude automatically uses them when relevant to your task.

### Skill vs MCP Server

This project is distinct from the [official beads plugin](https://github.com/steveyegge/beads/blob/main/docs/PLUGIN.md):

- **This plugin** (skill-based): Provides workflow knowledge, best practices, and command reference for working with beads. Teaches Claude *how* and *when* to use beads effectively.
- **Official plugin** (MCP server): Provides slash commands (`/bd-init`, `/bd-ready`, etc.) and tools for executing beads CLI operations. Enables Claude to *interact with* beads infrastructure.

Both can be used together: this skill teaches the methodology, while the official MCP server provides the integration.

## Skills

### beads-workflow

Workflow patterns for beads issue tracking:

- Session close protocol (sync and push before claiming done)
- Dependency direction ("needs" not "comes before")
- Core `bd` command reference
- Issue types and priorities
- Git worktree support

**Supplementary docs** (not loaded with skill):
- [Setup & Configuration](skills/beads-workflow/docs/setup.md) - Installation, daemon config, architecture
- [CLI Reference](skills/beads-workflow/docs/cli-reference.md) - Complete command reference

## Installation

Add to your Claude Code plugins:

```bash
# From GitHub
/plugin add chrisvaillancourt/beads-plugin

# Or clone and add locally
git clone https://github.com/chrisvaillancourt/beads-plugin.git
/plugin add /path/to/beads-plugin
```

## Usage

The skill is automatically available in Claude Code conversations when working in projects with a `.beads/` directory. Reference it with the Skill tool or it will be suggested when relevant.

## License

MIT
