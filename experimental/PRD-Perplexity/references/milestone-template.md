# Phased Project Plan: {{PRODUCT_NAME}}

> **Companion to**: PRD v{{VERSION}}
> **Status**: Draft / Locked
> **Last Updated**: {{DATE}}

---

## Milestone Philosophy

Each milestone is a **vertical slice** of functionality that delivers independently testable value. Milestones are sequenced to minimize risk: foundation first, core flows second, edge cases and advanced features last.

**Rules for milestone scope:**
- Each milestone must be completable in 1 focused implementation session
- Each milestone has explicit completion criteria that can be verified
- Milestones depend only on previously completed milestones
- No milestone may add scope beyond what is locked in the PRD

---

## Milestone 1: Foundation

**Theme**: Project scaffolding, database, authentication

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| Database schema (all tables from PRD §5) | Business logic beyond auth |
| Authentication system (login/signup/logout) | UI screens beyond auth flows |
| Project structure & tooling setup | API endpoints for domain entities |
| CI/CD pipeline skeleton | Background jobs |
| Development environment configuration | Third-party integrations |

### Dependencies
- None (first milestone)

### Completion Criteria

- [ ] Database migrations run successfully and schema matches PRD §5
- [ ] User can sign up with email/password
- [ ] User can log in and receive valid session/token
- [ ] User can log out and session is invalidated
- [ ] Project builds without errors
- [ ] Type checking passes
- [ ] Linting passes
- [ ] Test framework runs and at least one auth test passes

### Implementation Prompt

```
Set up the project foundation for {{PRODUCT_NAME}}:

DATABASE:
- Create all tables from the locked PRD data model (§5): {{ENTITY_LIST}}
- Set up migrations framework
- Create seed data for development

AUTHENTICATION:
- Implement email/password signup with validation
- Implement login with secure session/token management
- Implement logout with proper session invalidation
- Add password hashing (bcrypt/argon2)

PROJECT SETUP:
- Initialize project with chosen framework/stack
- Configure development environment
- Set up build pipeline
- Configure linting and type checking
- Set up test framework with at least one passing auth test

ACCEPTANCE: All completion criteria above must pass.
```

---

## Milestone 2: Core Data Layer

**Theme**: API endpoints, CRUD operations, data validation

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| REST/GraphQL API for all domain entities | UI/frontend screens |
| Full CRUD for primary entities | Complex business logic workflows |
| Input validation & error handling | Real-time updates / WebSockets |
| Authorization middleware (role/ownership checks) | Background job processing |
| API documentation / OpenAPI spec | External integrations |

### Dependencies
- Milestone 1 (Foundation)

### Completion Criteria

- [ ] All entities from PRD §5 have create, read, update, delete endpoints
- [ ] Input validation returns clear 400 errors for invalid data
- [ ] Authorization prevents unauthorized access to resources
- [ ] All endpoints return consistent error response format
- [ ] API tests cover happy path and error cases for each endpoint
- [ ] OpenAPI/Swagger spec is auto-generated or manually documented

### Implementation Prompt

```
Build the core data layer for {{PRODUCT_NAME}}:

API ENDPOINTS:
- Implement CRUD for: {{ENTITY_LIST}}
- Follow RESTful conventions (or GraphQL schema if applicable)
- All endpoints require valid authentication from M1

VALIDATION:
- Validate all inputs against PRD §3 requirements
- Return structured 400 errors with field-level messages
- Validate foreign key constraints and referential integrity

AUTHORIZATION:
- Implement resource-level ownership checks
- Return 403 for unauthorized access attempts

TESTING:
- Write API tests for every endpoint (happy path + errors)
- Verify authorization rules with test cases
- All tests must pass

ACCEPTANCE: All completion criteria above must pass.
```

---

## Milestone 3: Primary User Flows

**Theme**: Core screens, interactions, end-to-end workflows

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| All P0 UI screens from PRD §4 | P1/P2 screens |
| End-to-end user flows (frontend → API → DB) | Admin/dashboard views |
| Form submissions with validation | Advanced filtering/search |
| Loading states and error UI | Real-time features |
| Mobile-responsive layout | Offline support |

### Dependencies
- Milestone 1 (Foundation)
- Milestone 2 (Core Data Layer)

### Completion Criteria

- [ ] All P0 user flows from PRD §4 are fully functional end-to-end
- [ ] Forms validate client-side and display server errors
- [ ] Loading states shown during async operations
- [ ] Error states handled gracefully (not just console errors)
- [ ] UI is usable on desktop and mobile screen sizes
- [ ] Type checking passes
- [ ] Each flow can be verified in browser: {{LIST_KEY_FLOWS}}

### Implementation Prompt

```
Implement the primary user flows for {{PRODUCT_NAME}}:

FLOWS TO BUILD:
{{FLOW_LIST}}

FOR EACH FLOW:
- Build the UI screens with form validation
- Connect to API endpoints from M2
- Handle loading, error, and empty states
- Ensure responsive design (desktop + mobile)

UI STANDARDS:
- Loading states for all async operations
- Error messages displayed to user (not just console)
- Form validation: client-side first, server errors displayed inline
- Success confirmations for destructive actions

TESTING:
- Manually verify each flow in browser
- Test error paths (network failure, invalid input)
- Test on mobile viewport size

ACCEPTANCE: All P0 flows work end-to-end. Typecheck passes. Verify in browser.
```

---

## Milestone 4: Edge Cases, Polish & Non-Functional

**Theme**: Error handling, empty states, performance, security hardening

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| Empty states for all list views | P1/P2 features |
| Error boundaries and crash recovery | Advanced analytics |
| Rate limiting on API endpoints | Background processing |
| Input sanitization / XSS prevention | Third-party integrations |
| Performance: N+1 query elimination | WebSocket/real-time |
| Accessibility pass (keyboard nav, ARIA labels) | Mobile native app |

### Dependencies
- Milestone 1 (Foundation)
- Milestone 2 (Core Data Layer)
- Milestone 3 (Primary User Flows)

### Completion Criteria

- [ ] All list views show designed empty states (not blank screens)
- [ ] App handles unexpected errors gracefully (no white screens)
- [ ] API has rate limiting on auth and write endpoints
- [ ] No N+1 query problems on primary flows (verified with logging)
- [ ] All interactive elements keyboard accessible
- [ ] Security: XSS protection, CSRF where applicable, input sanitization
- [ ] Lighthouse score > {{TARGET_SCORE}} on primary pages

### Implementation Prompt

```
Polish {{PRODUCT_NAME}} with edge cases and non-functional requirements:

EDGE CASES:
- Empty states: design and implement for every list view
- Error handling: wrap routes in error boundaries
- Network failure: retry logic and user-facing error messages
- Rate limiting: implement on auth and write endpoints

PERFORMANCE:
- Audit and fix N+1 queries on primary flows
- Add database indexes for common query patterns
- Optimize bundle size if applicable

SECURITY:
- Sanitize all user inputs (XSS prevention)
- Add CSRF protection if using session cookies
- Verify auth middleware covers all protected routes

ACCESSIBILITY:
- Keyboard navigation works for all flows
- ARIA labels on interactive elements
- Focus management on route changes

TESTING:
- Run Lighthouse audit on primary pages
- Manually test with keyboard only
- Verify empty states render correctly

ACCEPTANCE: All completion criteria above must pass.
```

---

## Milestone 5+: Advanced Features & Integrations

**Theme**: P1 requirements, third-party integrations, advanced functionality

### Scope

Based on P1/P2 requirements from PRD §3.2 and §3.3, create additional milestones following the same structure.

### Template for Additional Milestones

For each advanced feature set, create a milestone following this format:

```markdown
## Milestone {{N}}: {{Feature Area}}

**Theme**: {{one-line description}}

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| {{feature 1}} | {{deferred item}} |

### Dependencies
- Milestone {{X}}, {{Y}}

### Completion Criteria
- [ ] {{criterion 1}}
- [ ] {{criterion 2}}

### Implementation Prompt
{{Agent-ready prompt for implementation}}
```

---

## Milestone Execution Log

Track actual completion as milestones are delivered:

| Milestone | Planned Date | Actual Date | Status | Notes |
|-----------|-------------|-------------|--------|-------|
| M1: Foundation | {{date}} | | Not Started | |
| M2: Core Data | {{date}} | | Not Started | |
| M3: Primary Flows | {{date}} | | Not Started | |
| M4: Polish | {{date}} | | Not Started | |
| M5+: Advanced | {{date}} | | Not Started | |

---

*Generated by PRD Creator — Spec-Driven Milestone Planning*
