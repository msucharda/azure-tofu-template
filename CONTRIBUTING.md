# Contributing

This project uses an AI-assisted development workflow powered by
GitHub Copilot CLI and speckit agents.

## Development Workflow

### Using Copilot CLI

Copilot CLI is the recommended interface for all operations:

```bash
# Plan changes
tofu plan -var-file=environments/dev.tfvars

# Apply changes (local, for testing only)
tofu apply -var-file=environments/dev.tfvars

# Format code
tofu fmt -recursive

# Validate configuration
tofu validate
```

### Using Speckit Agents

For new features or significant changes, use the speckit workflow:

1. **Specify** — Define requirements: `/speckit.specify`
2. **Plan** — Design implementation: `/speckit.plan`
3. **Tasks** — Break into actionable tasks: `/speckit.tasks`
4. **Implement** — Execute the plan: `/speckit.implement`

## Adding a New Module

1. Create the module directory: `modules/<name>/`
2. Create `main.tf` — wrapper around an AVM module with pinned version
3. Create `variables.tf` — all inputs with descriptions, types, and validation
4. Create `outputs.tf` — expose key attributes
5. Create `README.md` — document purpose, inputs, outputs, and usage
6. Add a `module` block in root `main.tf` with a toggle variable
7. Add the toggle variable to `variables.tf` with a default
8. Add outputs to root `outputs.tf`
9. Add variable values to each `environments/*.tfvars`
10. Run `tofu fmt -recursive && tofu validate`

## PR Conventions

### Branch Naming

```
feature/<description>     — New features or resources
fix/<description>          — Bug fixes
hotfix/<description>       — Emergency production fixes
docs/<description>         — Documentation changes
refactor/<description>     — Code restructuring
```

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add database module with AVM wrapper
fix: correct NSG rule ordering in networking module
docs: update onboarding guide with new prerequisites
refactor: simplify tag merging logic in modules
```

### PR Description

Include:
- **What** — brief description of the change
- **Why** — motivation and context
- **How** — implementation approach
- **Testing** — how you verified the change (plan output, etc.)

## Code Standards

### HCL Style

- Use `tofu fmt` — all files must pass format check
- One resource/module per logical block
- Variables before resources in module files
- Outputs at the end of module files

### Variables

- Always include `description` and `type`
- Add `validation` blocks for constrained values
- Use `default` only when a sensible default exists
- Group related variables with comment headers

### Naming

Follow Azure Cloud Adoption Framework (CAF) abbreviations:
- `rg-` for resource groups
- `vnet-` for virtual networks
- `id-` for managed identities
- `kv-` for key vaults
- `st` for storage accounts (no hyphens)

### Tagging

Every resource must include:
- `managed-by = "opentofu"` (enforced by modules)
- `environment` tag (set via base_tags in main.tf)

### Security

- **No secrets in code** — use Key Vault data sources
- **No broad RBAC** — least-privilege assignments only
- **Pin module versions** — use `~> X.Y` constraints
- **Review security scans** — address all HIGH/CRITICAL findings

## Quality Gates

All PRs must pass:

| Check | Tool | Description |
|-------|------|-------------|
| Format | `tofu fmt -check` | Code formatting |
| Validate | `tofu validate` | Configuration syntax |
| Plan | `tofu plan` | Infrastructure changes preview |
| Lint | `tflint` | Azure best practices |
| Security | checkov + trivy | Security vulnerability scanning |

## Getting Help

- Check `docs/` for runbooks and guides
- Use Copilot CLI to ask questions about the codebase
- Review module READMEs in `modules/<name>/README.md`
- Consult the [constitution](.specify/memory/constitution.md) for governance
