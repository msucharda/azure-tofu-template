# Tasks: Azure OpenTofu Template Repository

**Input**: Design documents from `/specs/001-azure-opentofu-template/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Not explicitly requested in the specification. Validation
is handled by pipeline tooling (tofu validate, tflint, checkov, trivy).

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- **IaC template repository**: Root directory is the OpenTofu root
  module. Modules in `modules/`, environment configs in
  `environments/` and `backend-config/`, workflows in
  `.github/workflows/`, scripts in `scripts/`, docs in `docs/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the project directory structure, provider
configuration, and tooling setup.

- [X] T001 Create directory structure: `modules/resource-group/`, `modules/networking/`, `modules/identity/`, `modules/key-vault/`, `modules/storage/`, `environments/`, `backend-config/`, `scripts/`, `docs/`
- [X] T002 [P] Create `.gitignore` with OpenTofu ignores (`.terraform/`, `*.tfstate`, `*.tfstate.backup`, `*.tfvars` overrides, crash logs) — NOTE: `.terraform.lock.hcl` MUST be committed for reproducible provider builds
- [X] T003 [P] Create `versions.tf` with `required_version >= 1.8` and `required_providers` block (azurerm >= 4.0, azapi >= 2.0) — azapi included for future raw-resource fallback per constitution Principle I; not used by baseline modules
- [X] T004 [P] Create `providers.tf` with azurerm provider configuration (features block, skip_provider_registration = false)
- [X] T005 [P] Create `.tflint.hcl` with tflint-ruleset-azurerm plugin configuration
- [X] T006 [P] Create `.trivyignore` with baseline false-positive suppressions (empty initially, with comment explaining purpose)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Backend configuration, root variable declarations, and
environment parameterization that ALL user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is
complete.

- [X] T007 Create `backend.tf` with partial azurerm backend configuration (resource_group_name, storage_account_name, container_name, key placeholders — completed at init time via `-backend-config`)
- [X] T008 [P] Create `backend-config/dev.hcl` with dev state backend values (storage account, container `tfstate-dev`, state key)
- [X] T009 [P] Create `backend-config/staging.hcl` with staging state backend values (storage account, container `tfstate-staging`, state key)
- [X] T010 [P] Create `backend-config/production.hcl` with production state backend values (storage account, container `tfstate-production`, state key)
- [X] T011 Create `variables.tf` with root module variable declarations: `subscription_id`, `location`, `environment`, `naming_prefix`, `tags` (map with `managed-by` default), and module-toggle booleans
- [X] T012 [P] Create `outputs.tf` with root module output declarations: resource group name/id, vnet name/id, identity principal id, key vault uri, storage account name
- [X] T013 [P] Create `environments/dev.tfvars` with dev-specific variable values (region, naming prefix, resource sizing, tags)
- [X] T014 [P] Create `environments/staging.tfvars` with staging-specific variable values
- [X] T015 [P] Create `environments/production.tfvars` with production-specific variable values

**Checkpoint**: Foundation ready — module development and story
implementation can now begin.

---

## Phase 3: User Story 1 — Subscription Onboarding (Priority: P1) 🎯 MVP

**Goal**: Deliver a complete template that can be cloned, configured,
and initialized for a new Azure subscription with working state
backend and baseline modules.

**Independent Test**: Create a new repo from the template, fill in
subscription parameters, run `./scripts/init-backend.sh dev`, then
`tofu plan -var-file=environments/dev.tfvars` — plan should succeed
with baseline resources to create.

### Implementation for User Story 1

- [X] T016 [P] [US1] Create `modules/resource-group/main.tf`, `modules/resource-group/variables.tf`, `modules/resource-group/outputs.tf` — wrapper around AVM `avm-res-resources-resourcegroup` with pinned version constraint, project tagging, and CAF naming defaults
- [X] T017 [P] [US1] Create `modules/networking/main.tf`, `modules/networking/variables.tf`, `modules/networking/outputs.tf` — wrapper around AVM `avm-res-network-virtualnetwork` with pinned version constraint, default subnet layout, and NSG association
- [X] T018 [P] [US1] Create `modules/identity/main.tf`, `modules/identity/variables.tf`, `modules/identity/outputs.tf` — wrapper around AVM `avm-res-managedidentity-userassignedidentity` with pinned version constraint for workload identity
- [X] T019 [P] [US1] Create `modules/key-vault/main.tf`, `modules/key-vault/variables.tf`, `modules/key-vault/outputs.tf` — wrapper around AVM `avm-res-keyvault-vault` with pinned version constraint, RBAC authorization, purge protection, and network rules. Include example data source pattern for consuming secrets from Key Vault in module comments
- [X] T020 [P] [US1] Create `modules/storage/main.tf`, `modules/storage/variables.tf`, `modules/storage/outputs.tf` — wrapper around AVM `avm-res-storage-storageaccount` with pinned version constraint, encryption, HTTPS-only, and versioning defaults
- [X] T021 [US1] Create `main.tf` root module composing all 5 modules with `module` blocks, dependency ordering (resource-group first, then parallel), and conditional toggles (depends on T016–T020)
- [X] T022 [US1] Create `scripts/init-backend.sh` — accepts environment name, provisions storage account if needed, creates blob container, enables versioning, runs `tofu init -backend-config=backend-config/<env>.hcl`
- [X] T023 [P] [US1] Create `docs/onboarding.md` with step-by-step new subscription setup guide (prerequisites, parameter configuration, backend init, first plan, branch creation)
- [X] T024 [US1] Create `README.md` with project overview, directory structure, quick-start reference, and links to detailed docs

**Checkpoint**: At this point, the template can be cloned, configured,
and initialized for a new subscription. `tofu plan` succeeds with
baseline resources. This is a functional MVP.

---

## Phase 4: User Story 2 — Safe Infrastructure Changes via PR (Priority: P2)

**Goal**: Deliver GitHub Actions pipelines that validate PRs
(fmt/validate/plan/lint/scan), post results as PR comments, and
apply changes on merge with production approval gates.

**Independent Test**: Open a PR adding a new resource to dev, verify
pr-validate workflow runs and posts plan comment. Merge PR and verify
apply workflow provisions the change.

### Implementation for User Story 2

- [X] T025 [US2] Create `.github/workflows/pr-validate.yml` — triggers on PR to dev/staging/production branches; jobs: `tofu fmt -check`, `tofu validate`, `tofu plan` (with env detection from target branch), `tflint`, `checkov`/`trivy` scan; posts combined results as PR comment; uses OIDC auth per environment
- [X] T026 [US2] Create `.github/workflows/apply.yml` — triggers on push/merge to dev/staging/production branches; jobs: `tofu init`, `tofu plan`, `tofu apply -auto-approve`; production requires `environment: production` with manual approval; uses OIDC auth; env detection from branch name
- [X] T027 [P] [US2] Create `docs/making-changes.md` with PR workflow walkthrough (branch from env branch, make changes, open PR, review plan output, approve, merge, verify apply)
- [X] T028 [US2] Create `docs/identity-setup.md` documenting OIDC Workload Identity Federation setup: service principal creation per environment, federated credential configuration scoped to environment branch subject claims, minimum RBAC role assignments, and Azure AD app registration steps
- [X] T029 [US2] Create `docs/github-setup.md` documenting required GitHub configuration: branch protection rules for dev/staging/production (require PR, require status checks, no direct push), GitHub environment creation with required reviewers (1 for dev/staging, 2 for production), and environment secrets for OIDC (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`)

**Checkpoint**: PR-driven workflow is fully operational. Changes are
validated before merge, applied after merge, and production requires
manual approval. Identity and GitHub configuration are documented.

---

## Phase 5: User Story 3 — Modular Resource Organization (Priority: P3)

**Goal**: Ensure all modules follow consistent patterns — explicit
variable definitions with validation, CAF naming conventions,
mandatory tagging, and per-module documentation.

**Independent Test**: Inspect any module and verify: variables have
descriptions/types/validation, naming follows CAF, `managed-by` tag
is present, and README explains the module's purpose and usage.

### Implementation for User Story 3

- [X] T030 [US3] Add `validation` blocks to all module variables in `modules/*/variables.tf` — enforce allowed values, string patterns, and non-empty constraints where applicable
- [X] T031 [US3] Add CAF naming convention locals to each module (or create shared `naming.tf` at root) using Azure CAF abbreviation conventions for resource type prefixes
- [X] T032 [US3] Ensure all modules apply mandatory `managed-by = "opentofu"` tag via merged tag maps in `modules/*/main.tf` — verify no resource can be created without this tag
- [X] T033 [P] [US3] Create `modules/resource-group/README.md`, `modules/networking/README.md`, `modules/identity/README.md`, `modules/key-vault/README.md`, `modules/storage/README.md` — each documenting purpose, inputs, outputs, AVM source, and usage example

**Checkpoint**: All modules are consistently organized, validated,
named, tagged, and documented. An engineer (or AI agent) can
understand any module by reading its README and variable definitions.

---

## Phase 6: User Story 4 — Controlled Infrastructure Destruction (Priority: P4)

**Goal**: Deliver a destroy workflow with mandatory manual confirmation
and documentation for safe teardown procedures.

**Independent Test**: Provision resources in dev, trigger destroy
workflow via GitHub Actions UI, verify it shows destruction plan and
requires confirmation before executing.

### Implementation for User Story 4

- [X] T034 [US4] Create `.github/workflows/destroy.yml` — manual `workflow_dispatch` trigger with environment input; jobs: `tofu init`, `tofu plan -destroy` (posted as summary), manual approval gate (all environments), `tofu apply -destroy`; uses OIDC auth
- [X] T035 [P] [US4] Create `docs/destroying-resources.md` with safe teardown procedures: when to destroy, pre-destroy checklist (backup state, confirm scope), triggering the workflow, verifying cleanup, handling resources with deletion protection

**Checkpoint**: Destruction is safe, auditable, and documented.
No resources can be destroyed without explicit confirmation.

---

## Phase 7: User Story 5 — State Recovery (Priority: P5)

**Goal**: Deliver helper scripts and a comprehensive runbook for state
restore, resource import, and drift detection.

**Independent Test**: Delete the dev state file, run
`./scripts/state-recover.sh dev`, verify state is restored from blob
version. Run `./scripts/drift-detect.sh dev`, verify it reports
current state accurately.

### Implementation for User Story 5

- [X] T036 [P] [US5] Create `scripts/state-recover.sh` — accepts environment name; lists available blob versions; prompts for version selection; restores selected version as current state blob; runs `tofu plan` to verify recovery
- [X] T037 [P] [US5] Create `scripts/state-import.sh` — accepts environment, resource address, Azure resource ID; runs `tofu import` with correct backend and var-file; verifies import with `tofu plan`
- [X] T038 [P] [US5] Create `scripts/drift-detect.sh` — accepts environment name; runs `tofu plan` and parses output for changes; reports drift summary (resources to add/change/destroy); exits non-zero if drift detected
- [X] T039 [US5] Create `docs/state-recovery.md` with recovery runbook: diagnosing state issues, restoring from blob version backup, importing existing resources, resolving drift, `state mv` operations, emergency procedures, and troubleshooting backend connectivity failures

**Checkpoint**: State recovery is documented and scripted. Engineers
can recover from state file loss, drift, or corruption without panic.

---

## Phase 8: User Story 6 — AI-Assisted Development Experience (Priority: P6)

**Goal**: Optimize the repository structure and documentation for
effective use with GitHub Copilot CLI and AI agents.

**Independent Test**: Use Copilot CLI to ask about the project
structure, add a new resource, and troubleshoot an error — verify the
AI produces accurate, convention-following responses.

### Implementation for User Story 6

- [X] T040 [US6] Update `.github/agents/copilot-instructions.md` with detailed project conventions: module patterns, file naming, variable declaration style, tagging requirements, PR workflow, AVM-first rule, and common operation examples
- [X] T041 [P] [US6] Add descriptive header comments to all root `.tf` files (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `versions.tf`, `backend.tf`) explaining each file's purpose and relationship to other files
- [X] T042 [P] [US6] Create `CONTRIBUTING.md` with AI-assisted workflow guidelines: using Copilot CLI for plan/apply, speckit workflow for features, PR conventions, commit message format, and how to add new modules

**Checkpoint**: The repository is fully optimized for AI-assisted
development. Copilot CLI can reason about the project effectively.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup across all user stories.

- [X] T043 [P] Run `tofu fmt -recursive` on all `.tf` files and commit formatting fixes
- [X] T044 Run `tofu validate` to verify the complete project configuration parses correctly
- [X] T045 [P] Security audit — grep entire repository for potential secrets, API keys, passwords; verify `.gitignore` covers sensitive files
- [X] T046 Validate `quickstart.md` walkthrough against actual project structure — verify all referenced paths, commands, and procedures match reality

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — first story to implement
- **US2 (Phase 4)**: Depends on Phase 2; benefits from US1 for meaningful plan output
- **US3 (Phase 5)**: Depends on US1 (refines modules created in US1)
- **US4 (Phase 6)**: Depends on Phase 2; benefits from US1 for meaningful destroy
- **US5 (Phase 7)**: Depends on Phase 2 (scripts need backend config)
- **US6 (Phase 8)**: Depends on US1 (needs project structure to document)
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — no dependencies on other stories
- **US2 (P2)**: Can start after Phase 2 — independent of US1 but richer with it
- **US3 (P3)**: Depends on US1 — refines modules that US1 creates
- **US4 (P4)**: Can start after Phase 2 — independent of other stories
- **US5 (P5)**: Can start after Phase 2 — independent of other stories
- **US6 (P6)**: Depends on US1 — needs project structure to be in place

### Within Each User Story

- Module files before root composition (main.tf)
- Scripts before documentation that references them
- Core implementation before integration

### Parallel Opportunities

- Phase 1: T002–T006 can all run in parallel
- Phase 2: T008–T010 (backend configs) in parallel; T013–T015 (tfvars) in parallel
- US1: T016–T020 (all 5 modules) can run in parallel
- US2: T027 (docs) in parallel with T025 or T026; T028 and T029 (docs) in parallel
- US3: T033 (module READMEs) in parallel with T030–T032
- US5: T036–T038 (all 3 scripts) can run in parallel
- US6: T041 and T042 in parallel
- After Phase 2: US2, US4, and US5 can start in parallel with US1

---

## Parallel Example: User Story 1

```bash
# Launch all 5 module implementations together:
Task: T016 "Create modules/resource-group/ (main.tf, variables.tf, outputs.tf)"
Task: T017 "Create modules/networking/ (main.tf, variables.tf, outputs.tf)"
Task: T018 "Create modules/identity/ (main.tf, variables.tf, outputs.tf)"
Task: T019 "Create modules/key-vault/ (main.tf, variables.tf, outputs.tf)"
Task: T020 "Create modules/storage/ (main.tf, variables.tf, outputs.tf)"

# Then compose them in root:
Task: T021 "Create main.tf root module composing all 5 modules"

# Documentation in parallel with scripts:
Task: T022 "Create scripts/init-backend.sh"
Task: T023 "Create docs/onboarding.md"  # parallel with T022
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (Subscription Onboarding)
4. **STOP and VALIDATE**: Clone template, configure, init, plan
5. The template is usable for basic infrastructure management

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1 (Onboarding) → Template works end-to-end (MVP!)
3. US2 (PR Pipelines) → Automated validation and apply
4. US3 (Module Organization) → Consistent, documented modules
5. US4 (Destruction) → Safe teardown capability
6. US5 (State Recovery) → Resilience and recovery tooling
7. US6 (AI Experience) → Optimized for Copilot CLI
8. Polish → Final validation and cleanup

### Parallel Team Strategy

With multiple developers after Phase 2:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (Onboarding) — highest priority, MVP
   - Developer B: US2 (Pipelines) + US4 (Destroy) — CI/CD focus
   - Developer C: US5 (State Recovery) — scripts focus
3. After US1 completes:
   - Developer A: US3 (Module refinement) → US6 (AI experience)
   - Others continue their stories
4. All converge for Polish phase

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable at its checkpoint
- Commit after each task or logical group
- Stop at any checkpoint to validate the story independently
- All AVM module references must include version pins
- All scripts must be executable (`chmod +x`) and include usage help
- No secrets in any committed file — use placeholder values with comments
