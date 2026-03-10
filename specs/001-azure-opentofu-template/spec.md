# Feature Specification: Azure OpenTofu Template Repository

**Feature Branch**: `001-azure-opentofu-template`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Azure OpenTofu Template Repository — a GitHub template repository for managing Azure infrastructure via OpenTofu for every new subscription"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Subscription Onboarding (Priority: P1)

A platform engineer receives a new Azure subscription and needs to
stand up infrastructure management for it. They create a new
repository from this template, configure the subscription-specific
values (subscription ID, region, naming prefix), and initialize the
remote state backend. After initialization, the repository is ready
for the team to start defining and deploying infrastructure through
pull requests.

**Why this priority**: Without a working template that can be
initialized for a new subscription, no other capability delivers
value. This is the foundational use case — every other story depends
on having an initialized, functional repository.

**Independent Test**: Can be fully tested by creating a new repository
from the template, filling in subscription parameters, and
successfully initializing the remote state backend. Delivers a
ready-to-use IaC repository for the subscription.

**Acceptance Scenarios**:

1. **Given** a new Azure subscription with no infrastructure
   management, **When** an engineer creates a repository from this
   template and configures the subscription parameters, **Then** the
   repository contains a valid project structure with environment
   branches (dev, staging, production), remote state backend
   configuration, and a baseline set of modules ready for
   customization.

2. **Given** a freshly created repository from the template, **When**
   the engineer runs the initialization process for the dev
   environment, **Then** the remote state backend is provisioned with
   a dedicated storage container, state locking is active, and the
   first plan completes successfully with no errors.

3. **Given** an initialized repository, **When** the engineer reviews
   the project structure, **Then** all configuration files follow
   naming conventions, modules use Azure Verified Modules, no secrets
   are present in any file, and documentation explains how to proceed
   with each environment.

---

### User Story 2 — Safe Infrastructure Changes via PR (Priority: P2)

An infrastructure developer needs to add or modify Azure resources for
a specific environment. They create a feature branch from the target
environment branch, make their changes, and open a pull request. The
automated pipeline validates the changes (formatting, syntax,
security, plan preview) and posts the results on the PR. After review
and approval, the merge triggers the apply workflow which provisions
the changes in Azure.

**Why this priority**: The PR-driven change workflow is the primary
daily interaction model. Without automated validation and safe apply,
teams either skip reviews or deploy manually — both leading to
configuration drift and security gaps.

**Independent Test**: Can be tested by opening a PR that adds a
single resource, verifying the pipeline runs all validation checks,
posts the plan output, and (after merge) applies the change
successfully to the target environment.

**Acceptance Scenarios**:

1. **Given** an initialized repository with a dev environment branch,
   **When** a developer opens a PR that modifies infrastructure
   configuration, **Then** the pipeline automatically runs format
   validation, syntax validation, a plan preview, linting, and
   security scanning, and posts all results as a PR comment.

2. **Given** a PR with all checks passing and the required approvals,
   **When** the PR is merged to the environment branch, **Then** the
   apply workflow executes and provisions the changes in the target
   Azure environment.

3. **Given** a PR that introduces a security violation (e.g., a
   publicly exposed storage account), **When** the pipeline runs,
   **Then** the security scan fails, the PR is blocked from merging,
   and the violation details are reported in the PR comment.

4. **Given** a PR targeting the production branch, **When** the merge
   triggers the apply workflow, **Then** the workflow pauses for
   manual approval before executing the apply step.

---

### User Story 3 — Modular Resource Organization (Priority: P3)

A platform engineer needs to define Azure resources in a consistent,
reusable way across environments. They use the template's module
structure to compose infrastructure from pre-configured building
blocks (networking, identity, storage, key vault), with each
environment consuming the same modules but with environment-specific
variable values.

**Why this priority**: Modular organization prevents configuration
drift between environments and reduces duplication. It makes the
codebase navigable for both humans and AI tools, and ensures that
changes are applied consistently.

**Independent Test**: Can be tested by examining the module structure,
verifying that all modules reference Azure Verified Modules, and
confirming that dev and production environments use the same modules
with different variable files.

**Acceptance Scenarios**:

1. **Given** an initialized repository, **When** an engineer inspects
   the module layout, **Then** each module has a single
   responsibility, references Azure Verified Modules, and includes
   explicit input/output variable definitions.

2. **Given** the same set of modules, **When** the engineer compares
   the dev and production configurations, **Then** the module sources
   are identical and only variable values differ between environments.

3. **Given** a module that provisions a resource, **When** the
   resource definition is reviewed, **Then** it uses an Azure Verified
   Module (or includes a documented justification for using a raw
   resource block with a link to the AVM tracking issue).

---

### User Story 4 — Controlled Infrastructure Destruction (Priority: P4)

A platform engineer needs to tear down all or part of the
infrastructure in an environment — either for decommissioning, cost
savings, or environment reset. They trigger the destroy workflow which
shows what will be removed, requires explicit confirmation, and
executes the teardown in dependency-aware order.

**Why this priority**: Destruction is a high-risk operation that must
be intentional and auditable. Without a safe destroy workflow, teams
resort to manual deletion in the portal, leaving orphaned resources
and state drift.

**Independent Test**: Can be tested by provisioning a small set of
resources in a dev environment and then running the destroy workflow
to verify it plans the destruction, requires confirmation, and removes
all resources cleanly.

**Acceptance Scenarios**:

1. **Given** a dev environment with provisioned resources, **When** an
   engineer triggers the destroy workflow, **Then** the system
   displays a destruction plan listing every resource to be removed
   and pauses for explicit manual confirmation.

2. **Given** confirmation is provided, **When** the destroy executes,
   **Then** all targeted resources are removed in dependency-aware
   order and the state file reflects the empty state.

3. **Given** a destroy workflow is triggered, **When** the engineer
   does not confirm within the timeout period, **Then** no resources
   are destroyed and the workflow exits cleanly.

---

### User Story 5 — State Recovery (Priority: P5)

A platform engineer discovers that the state file is corrupted, out of
sync with actual Azure resources, or accidentally deleted. They follow
documented recovery procedures to restore state from backups, re-import
existing resources, or reconcile drift between state and reality.

**Why this priority**: State file issues are inevitable over a long
enough timeline. Without recovery procedures, teams face hours of
manual reconstruction or worse — accidental destruction of production
resources on the next apply.

**Independent Test**: Can be tested by deliberately corrupting or
deleting the dev state file and then following the recovery runbook to
restore it from a versioned backup or re-import resources.

**Acceptance Scenarios**:

1. **Given** a state file that has been accidentally deleted, **When**
   the engineer follows the restore procedure, **Then** the state file
   is recovered from the versioned blob storage backup and subsequent
   plan shows no unexpected changes.

2. **Given** resources exist in Azure but are missing from the state
   file, **When** the engineer follows the import procedure, **Then**
   the resources are imported into state and a subsequent plan shows
   no drift.

3. **Given** the state file has drifted from actual Azure resources,
   **When** the engineer runs the drift detection procedure, **Then**
   discrepancies are listed with actionable guidance on whether to
   update state or update infrastructure to reconcile.

---

### User Story 6 — AI-Assisted Development Experience (Priority: P6)

An infrastructure developer uses GitHub Copilot CLI as their primary
interface for working with this repository. The project structure,
naming conventions, documentation, and module design make it easy for
AI tools to understand context, suggest changes, and execute operations
(plan, apply, troubleshoot) through natural language interaction.

**Why this priority**: While the template works without AI tools, the
developer experience is significantly better when the codebase is
structured for AI readability. This is a quality-of-life enhancement
that improves velocity for the target audience.

**Independent Test**: Can be tested by using Copilot CLI to perform
common operations (run a plan, add a new resource, troubleshoot an
error) and verifying that the AI agent can reason about the project
structure effectively.

**Acceptance Scenarios**:

1. **Given** an initialized repository, **When** a developer asks the
   AI agent to explain the project structure, **Then** the agent can
   accurately describe the environment layout, module organization,
   and workflow for making changes.

2. **Given** a request to add a new Azure resource, **When** the
   developer describes the resource in natural language to the AI
   agent, **Then** the agent produces configuration that follows the
   project conventions, uses Azure Verified Modules, and places files
   in the correct locations.

3. **Given** a failed plan or apply, **When** the developer asks the
   AI agent to diagnose the error, **Then** the agent can locate the
   relevant configuration, identify the issue, and suggest a fix
   consistent with the project's constitution.

---

### Edge Cases

- What happens when two engineers open PRs targeting the same
  environment branch simultaneously? (State locking prevents
  concurrent applies; the second apply waits or fails gracefully)
- What happens when the remote state backend storage account is
  inaccessible? (Operations fail with a clear error message pointing
  to backend connectivity; no local fallback to prevent split-brain)
- What happens when a module version referenced in the configuration
  is no longer available? (Plan fails with a dependency resolution
  error; pinned versions and lock files prevent silent upgrades)
- What happens when a destroy is run against an environment that has
  resources with deletion protection enabled? (Destroy plan reports
  the protected resources; engineer must explicitly remove protection
  before retrying)
- What happens when an Azure Verified Module does not exist for a
  required resource type? (Developer uses a raw resource block with
  mandatory justification comment and AVM tracking issue link, per
  constitution principle I)

## Requirements *(mandatory)*

### Functional Requirements

**Project Structure & Initialization**

- **FR-001**: Template MUST provide a project structure with separate
  configuration per environment (dev, staging, production), each
  backed by an independent remote state file.
- **FR-002**: Template MUST include an initialization procedure that
  provisions the remote state backend (storage container, locking
  mechanism) for a given environment.
- **FR-003**: Template MUST ship with a baseline set of modules for
  common Azure resources (resource groups, networking, identity
  management, secrets management, storage) using Azure Verified
  Modules.
- **FR-004**: Template MUST include environment-specific variable
  files that allow teams to customize resource properties per
  environment without modifying module source code.

**CI/CD Pipelines**

- **FR-005**: Template MUST include a pull request validation pipeline
  that runs format checking, syntax validation, plan preview, linting,
  and security scanning on every PR.
- **FR-006**: Pipeline MUST post the plan output and scan results as a
  comment on the pull request for reviewer visibility.
- **FR-007**: Template MUST include an apply pipeline that triggers on
  merge to an environment branch and provisions changes in the target
  Azure subscription.
- **FR-008**: Apply pipeline for production MUST require explicit
  manual approval before executing.
- **FR-009**: Template MUST include a destroy pipeline that displays a
  destruction plan and requires explicit manual confirmation before
  executing.

**Security**

- **FR-010**: Template MUST NOT contain any hardcoded credentials,
  secrets, or tokens in any file.
- **FR-011**: Template MUST integrate with a secrets management
  approach for handling sensitive configuration values.
- **FR-012**: Security scanning MUST run as part of every pull request
  pipeline and block merge on critical findings.
- **FR-013**: Deployment identity MUST follow least-privilege
  principles — scoped to only the permissions required for the target
  environment.

**State Management**

- **FR-014**: Each environment MUST have exactly one state file stored
  remotely with encryption at rest.
- **FR-015**: State locking MUST be enabled to prevent concurrent
  modifications.
- **FR-016**: State backend MUST support versioning to enable
  point-in-time recovery of state files.
- **FR-017**: Template MUST include documented procedures for state
  import, state move, drift detection, and state restore from backup.

**Developer Experience**

- **FR-018**: All modules MUST follow consistent naming conventions
  aligned with Azure Cloud Adoption Framework guidance.
- **FR-019**: All modules MUST have explicit input variable
  definitions with descriptions and type constraints.
- **FR-020**: Template MUST include documentation covering: project
  structure overview, onboarding a new subscription, making changes
  via PR, destroying resources, and recovering state.
- **FR-021**: All resources provisioned by the template MUST be tagged
  with at minimum a `managed-by` tag.

### Key Entities

- **Environment**: A deployment target (dev, staging, production) with
  its own branch, state file, variable values, and backend
  configuration. Environments share module code but differ in
  parameterization.
- **Module**: A self-contained unit of infrastructure configuration
  that provisions one or more related Azure resources. References
  Azure Verified Modules and exposes inputs/outputs for composition.
- **State File**: The record of all resources managed within an
  environment. Stored remotely, locked during operations, versioned
  for recovery. Exactly one per environment.
- **Pipeline**: An automated workflow triggered by repository events
  (PR opened, branch merged, manual dispatch). Executes validation,
  planning, application, or destruction of infrastructure.
- **Deployment Identity**: The service principal or managed identity
  used by pipelines to authenticate with Azure and provision
  resources. Scoped per environment with least-privilege permissions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A platform engineer can create a new repository from the
  template and have a working IaC setup (with initialized state
  backend and passing first plan) within 30 minutes.
- **SC-002**: 100% of infrastructure changes flow through the PR
  validation pipeline — no mechanism exists to bypass it for
  environment branches.
- **SC-003**: Security scan findings at critical severity block PR
  merge in 100% of cases.
- **SC-004**: State recovery from a deleted or corrupted state file
  can be completed within 1 hour by following the documented runbook.
- **SC-005**: All environments use identical module source code — the
  only differences are variable values and backend configuration.
- **SC-006**: An engineer familiar with the template can add a new
  Azure resource (using an existing module pattern) and have it
  deployed to dev via PR within 15 minutes.
- **SC-007**: Zero secrets are present in the repository at any point
  — scannable and verifiable by automated tooling in the pipeline.
