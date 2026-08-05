# ChainReaction Development Rules

## Project Overview

- Engine: Love2D 11.5
- Language: Lua
- Genre: Puzzle Roguelite
- Core mechanic: Data-driven chain reactions

## Architecture Principles

- Prefer composition over inheritance.
- Prefer data-driven design over hardcoded gameplay logic.
- Keep gameplay rules independent from rendering.
- Use events for communication between systems.
- Minimize direct dependencies between modules.
- Avoid global state whenever possible.

## Code Style

- Use local variables by default.
- Keep functions small and focused.
- Use meaningful names.
- Avoid duplicated logic.
- Avoid large conditional branches.
- Add comments only when explaining design decisions.

## Gameplay Design

- New attributes should be added with minimal code changes.
- Objects should be defined through data whenever possible.
- Reaction logic should be extensible.
- Systems should not directly control unrelated systems.
- Prefer adding new gameplay content through data definitions rather than new code.

## Development Process

- Implement features in small steps.
- Explain architectural changes before making them.
- Do not introduce unnecessary frameworks.
- Prefer simple solutions over premature optimization.

## Architecture Boundaries

- Components contain data only.
- Gameplay logic belongs to reaction rules and systems.
- Reactions should be data-driven whenever possible.
- Systems resolve events and coordinate technical processes.
- Avoid implementing gameplay behavior inside entities or components.
