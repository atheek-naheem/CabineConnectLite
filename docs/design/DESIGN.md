# Design

> Produced in the `design` stage. Source of behaviour: `docs/requirements/REQUIREMENTS.md`.
> This document decides **how** to build the solution. It never changes **what** the
> solution must do. Requirements are referenced by ID, never restated.

## 1. Decisions

| ID | Decision | Options considered | Chosen | Decided by / why |
|---|---|---|---|---|
| D-001 | Language, runtime and HTTP framework | (a) Node.js + TypeScript with Express or Fastify; (b) Python + FastAPI; (c) .NET 8 minimal API; (d) Node.js with plain JavaScript | Node.js + TypeScript with **Express** | Atheek (engineer), 2026-09-28. Fastest scaffold the team knows; TypeScript keeps a five-state domain with 21 business rules honest. Express chosen over Fastify for familiarity and template support. |
| D-002 | Persistence | (a) SQLite with hand-written SQL; (b) SQLite through an ORM; (c) JSON file; and for the run contract: docker-compose, an external database, SQLite, or Postgres with a SQLite fallback | **PostgreSQL through Prisma**, with **SQLite as the documented fallback** for the fresh-clone check | Atheek (engineer), 2026-09-28. Postgres is the realistic target; the SQLite fallback keeps the `CHALLENGE.md` run contract satisfiable without Docker. Cost recorded as R-003. |
| D-003 | Interface | (a) Server-rendered HTML; (b) JSON API plus a static page; (c) API only | **Server-rendered HTML pages** | Atheek (engineer), 2026-09-28. No client build, one command to run, quickest to demonstrate the availability view. |
| D-004 | Test approach | (a) Domain unit tests plus API integration tests; (b) API integration tests only; (c) domain unit tests only | **Domain unit tests only**, with the resulting gaps accepted and recorded | Atheek (engineer), 2026-09-28. Fits the timebox and covers the rules precisely. AC-N001-1, AC-N003-1 and AC-014-1 cannot be verified this way; recorded as R-001 and R-002 and to be reported as known limitations, never as passing. |
| D-005 | Automatic expiry of an undecided request (REQ-012, BR-015) | (a) Derive on read and persist when observed; (b) scheduled sweep; (c) both | **Derive on read, persist the transition the first time it is observed**, writing one history entry attributed to the system | Atheek (engineer) delegated the choice — "don't over engineer this, do something simple" — and the AI took the simplest option, 2026-09-28. No scheduler, and correct even after the application has been stopped for days. Lag recorded as R-004. |
| D-006 | Overlap safety under concurrency (BR-001, ERR-013) | (a) Serialisable transaction with retry; (b) PostgreSQL range exclusion constraint; (c) in-process lock | **Overlap check and insert inside one serialisable transaction, retried once on a serialisation failure** | Atheek (engineer) delegated the choice, asking for simple, 2026-09-28. Simplest option that still satisfies ERR-013 ("no overlap is ever stored"); an exclusion constraint would need raw SQL and does not exist on SQLite, and an in-process lock breaks if a second instance runs. |
| D-007 | Reading "today" (BR-014) | (a) Injectable clock abstraction; (b) read the system clock where needed | **Pure domain functions take `today` as an explicit argument**; only the HTTP layer reads the system clock, as a UTC calendar date | Atheek (engineer) delegated the choice, asking for simple, 2026-09-28. One argument instead of a clock abstraction, and every date-dependent rule becomes directly unit-testable. |
| D-008 | How the acting user is selected and carried (REQ-013, NFR-004) | (a) Cookie set by a switcher control; (b) query parameter on every link; (c) server-side session | **A cookie holding the acting user's id, set by a switcher in the page header**; every request resolves it server-side before authorising | Atheek (engineer) delegated the choice, asking for simple, 2026-09-28. Survives navigation without rewriting every link, and needs no session store. Deliberately unauthenticated per SEC-003. |

Test runner: **Vitest**, implied by D-001 and D-004 as the simplest TypeScript unit-test setup. Flagged here rather than left silent.

## 2. Architecture

Three layers in one Express application. The dependency direction is one-way:
views and routes depend on the domain; the domain depends on nothing.

| Component | Responsibility | Serves |
|---|---|---|
| `domain/` | Pure TypeScript functions: date arithmetic, the rule checks, overlap and availability computation, and the state machine. No database, no HTTP, no clock. Returns either a result or a refusal naming the rule that blocked it. | BR-001 to BR-021, VAL-001 to VAL-016, NFR-006 |
| `repository/` | Prisma access: load and store bookings, users and state-change entries. Owns the serialisable transaction for submission and the append-only writes. | NFR-001, BR-017, ERR-013 |
| `web/` | Express routes, the acting-user cookie, authorisation entry point, server-rendered views and forms. Translates refusals into messages a resident understands. | REQ-001 to REQ-017, REQ-013, NFR-003, NFR-006 |

Every state-changing route follows the same shape: resolve the acting user, load
the booking, call one domain function with `today`, and persist only if the domain
returned success. Nothing decides permissions outside the domain layer.

## 3. Data model

Three tables. Nothing is ever deleted (BR-009, SEC-005).

| Entity | Fields | Notes |
|---|---|---|
| `User` | `id`, `name`, `role` (`MEMBER` \| `ADMIN`) | Seeded only; no creation path. Serves REQ-014, SEC-006. |
| `Booking` | `id`, `ownerId` → `User`, `checkIn` (date), `checkOut` (date), `state` (`PENDING` \| `APPROVED` \| `CANCELLED` \| `REJECTED` \| `EXPIRED`), `submittedAt` | Dates are whole calendar dates in UTC (BR-014). `ownerId` never changes (BR-012). `checkIn`/`checkOut` never change, including on a mid-stay cancellation (BR-011, A-024). |
| `StateChange` | `id`, `bookingId` → `Booking`, `state`, `actorUserId` → `User` (null = the system), `reason` (null, ≤ 500 chars), `occurredAt` (UTC timestamp) | Append-only; no update or delete path exists in the repository (BR-017, SEC-008). Serves REQ-015, REQ-016. |

Derived, never stored, so they cannot drift from the dates (Vocabulary section of the specification):

- `nights` = `checkOut − checkIn` (BR-002, BR-003)
- *holding* = state is `PENDING` or `APPROVED` (BR-001)
- *in progress* = `APPROVED` and `checkIn ≤ today < checkOut` (A-010)
- *finished* = `APPROVED` and `checkOut ≤ today` (BR-008)
- *unfinished* = holding and not finished — what BR-006 counts
- the reason shown for a booking = the `reason` on its most recent `StateChange` (REQ-004)

## 4. Booking state machine

`PENDING` is the only entry state (REQ-002). `CANCELLED`, `REJECTED` and `EXPIRED`
are terminal (BR-016). "Finished" is derived, not a state (BR-008).

| From | Transition | Who may trigger it | Conditions | Dates afterwards | IDs |
|---|---|---|---|---|---|
| — | submit | Member, for themselves only | VAL-001 to VAL-008 all pass | Held from submission | REQ-002, BR-010 |
| `PENDING` | approve | Administrator | State is `PENDING` | Still held | REQ-008, BR-016 |
| `PENDING` | reject (reason optional) | Administrator | State is `PENDING` | Freed entirely | REQ-009, BR-019 |
| `PENDING` | withdraw (reason optional) | Owner | `checkIn > today` | Freed entirely | REQ-006, BR-007 |
| `PENDING` | expire | System | `checkIn ≤ today`, no decision taken | Freed entirely | REQ-012, BR-015 |
| `APPROVED` | cancel (reason optional) | Owner | `checkIn > today` | Freed entirely | REQ-005, BR-007 |
| `APPROVED` | cancel (reason optional) | Administrator | `checkOut > today`, so including in progress | Freed from today onward; recorded dates unchanged | REQ-010, BR-008, BR-011 |

Every accepted transition writes exactly one `StateChange` (REQ-015). A refused
action writes nothing and changes nothing (VAL-012, AC-015-3). Availability is
computed only from holding bookings, so a terminal state frees its dates with no
extra bookkeeping (BR-009, EC-010).

## 5. Role enforcement

Authorisation lives in the domain layer, so it holds no matter how an action is
invoked (NFR-003, SEC-001).

- Every request resolves the acting user from the cookie (D-008). An unknown or
  absent id is refused before any data is read (VAL-013, ERR-015).
- Each domain function receives the acting user, the booking where relevant, and
  `today`, and checks role, then ownership, then state, then dates. It returns a
  refusal naming the rule (NFR-006), never a bare boolean.
- Member reads are scoped to their own bookings; a member asking about another
  booking gets the same refusal whether or not it exists (VAL-014, SEC-002, ERR-007).
- The pending queue and the state-change history are administrator-only, and the
  member view of their own booking renders state and reason but never the actor or
  timestamps (VAL-015, VAL-016, BR-018, SEC-007).
- Views hide controls the acting user may not use only as a convenience; the same
  request sent directly is refused by the same domain check (AC-N003-1, unverified
  under D-004 — see R-002).

## 6. Persistence and seed data

- Prisma schema and migration create the three tables; `npm start` applies
  migrations before serving, so a fresh clone needs no manual database step.
- PostgreSQL is the primary datasource; SQLite is the documented fallback (D-002).
  The schema stays within the feature subset both providers support (R-003).
- Seeding is idempotent and runs on start: exactly two members and one
  administrator with fixed ids and invented names, created only if absent, so a
  restart neither duplicates them nor disturbs existing bookings (REQ-014, A-018,
  SEC-006).
- Bookings, states, reasons and history entries live only in the database, which is
  what makes NFR-001 hold. Nothing is cached in memory across requests.

## 7. Test strategy

Vitest unit tests against the pure domain layer (D-004, D-007). Each test supplies
`today` explicitly, so boundary dates need no waiting and no mocked globals.

| Area | What is covered | IDs |
|---|---|---|
| Date and length rules | Minimum one night, maximum seven, check-in not in the past, check-out inside 90 days, and each boundary | BR-002, BR-003, BR-004, BR-005, BR-014, VAL-002 to VAL-005, EC-001 to EC-005, EC-018 |
| Overlap and availability | Night-level overlap, same-day turnover, availability across the window, fully booked window | BR-001, BR-013, VAL-006, EC-004, EC-009, EC-015, EC-016 |
| Booking limit | Pending and approved both counting, in-progress counting, a slot freed by cancellation | BR-006, VAL-007, EC-006 to EC-008, EC-014 |
| State machine and authorisation | Every transition in section 4, every refusal, role and ownership checks, terminal states, expiry on date rollover | BR-007 to BR-012, BR-015 to BR-020, VAL-008 to VAL-016, ERR-001 to ERR-019, EC-011 to EC-013, EC-023 |
| Reasons and history | Optional reason, the 500-character boundary, one entry per accepted change, none for a refusal, system-attributed expiry, member view omitting actor and timestamp | BR-017 to BR-019, EC-019 to EC-022, AC-015-1 to AC-015-3, AC-016-2 |
| Ordering | Every list by check-in date, soonest first, including the queue | A-026, AC-004-4, AC-007-2, AC-017-2 |

**Not verifiable under D-004**, to be reported as known limitations rather than as
passing: AC-N001-1 (restart persistence), AC-N003-1 (role enforcement with the
interface bypassed), AC-014-1 (seed data on a fresh start). That is 3 of the
specification's 44 acceptance criteria; the other 41 are reachable from the domain
layer. See R-001 and R-002.

## 8. Tasks

Ordered so the application runs end to end early. Each task is done when its
requirement IDs are demonstrably satisfied and its unit tests pass.

| ID | Task | Serves | Done when |
|---|---|---|---|
| T-001 | Project skeleton: TypeScript, Express, Vitest, npm `install` / `start` / `test` scripts, `.env.example` | D-001, NFR-002 | `npm test` runs an empty suite and `npm start` serves a page |
| T-002 | Prisma schema and first migration for `User`, `Booking`, `StateChange`; SQLite fallback documented | D-002, NFR-001, BR-017 | Migration applies on both providers and the tables exist |
| T-003 | Idempotent seed of two members and one administrator | REQ-014, A-018, SEC-006 | Restarting twice leaves exactly three users |
| T-004 | Domain: date helpers and the request rule checks | BR-002, BR-003, BR-004, BR-005, BR-014, VAL-001 to VAL-005 | Unit tests cover every boundary in section 7 |
| T-005 | Domain: overlap detection and availability over the window | BR-001, BR-013, REQ-001, VAL-006 | Unit tests cover turnover, overlap and a full window |
| T-006 | Domain: booking limit and the full state machine with authorisation and named refusals | BR-006 to BR-012, BR-015 to BR-021, VAL-007 to VAL-016, NFR-006 | Every transition and refusal in section 4 has a unit test |
| T-007 | Acting-user cookie, switcher, and the single authorisation entry point | REQ-013, NFR-003, NFR-004, SEC-001, SEC-003, ERR-015 | Switching user changes what every page allows |
| T-008 | Repository over Prisma, including submission inside a serialisable transaction with one retry, and append-only history writes | D-006, BR-001, BR-017, ERR-013 | Two concurrent overlapping submissions store exactly one booking |
| T-009 | Expiry derived on read, persisted once, with a system-attributed history entry | REQ-012, BR-015, EC-011, EC-020 | A pending request whose check-in has arrived reads as `Expired` and is no longer approvable |
| T-010 | Member pages: availability view, submit form, own bookings with order and reason, cancel and withdraw with optional reason | REQ-001, REQ-002, REQ-004, REQ-005, REQ-006, BR-019 | A member can complete every member action from the interface |
| T-011 | Administrator pages: all bookings, pending queue, approve, reject, cancel, and the state-change history | REQ-007, REQ-008, REQ-009, REQ-010, REQ-016, REQ-017, BR-018 | An administrator can complete every administrator action from the interface |
| T-012 | Refusal messages and empty states surfaced in the interface | NFR-006, ERR-001 to ERR-019, EC-016, EC-024 | Each refusal names the rule that blocked it |
| T-013 | README run contract: exact install, run and test commands for both providers, plus known limitations | Run contract, R-001 to R-004 | A fresh clone runs using only the README commands |

## 9. Requirement traceability

| Requirement | Design | Tasks |
|---|---|---|
| REQ-001 | §3 derived values, §5 | T-005, T-010 |
| REQ-002 | §4 submit, §6 | T-004, T-005, T-008, T-010 |
| REQ-003 | §2 route shape, §5 | T-004, T-006 |
| REQ-004 | §3 reason rule, §5 | T-010 |
| REQ-005 | §4 owner cancel | T-006, T-010 |
| REQ-006 | §4 withdraw | T-006, T-010 |
| REQ-007 | §5 | T-011 |
| REQ-008 | §4 approve | T-006, T-011 |
| REQ-009 | §4 reject | T-006, T-011 |
| REQ-010 | §4 administrator cancel | T-006, T-011 |
| REQ-011 | §4 availability from holding bookings | T-005, T-010, T-011 |
| REQ-012 | §4 expire, D-005 | T-009 |
| REQ-013 | §5, D-008 | T-007 |
| REQ-014 | §6 | T-003 |
| REQ-015 | §3 `StateChange`, §4 | T-006, T-008, T-009 |
| REQ-016 | §5 | T-011 |
| REQ-017 | §5 | T-011 |
| NFR-001 | §6 | T-002, T-013 |
| NFR-002 | D-001 | T-001 |
| NFR-003 | §2, §5 | T-006, T-007 |
| NFR-004 | D-008 | T-007 |
| NFR-005 | Nothing out of scope is designed | — |
| NFR-006 | §2 refusals, §5 | T-006, T-012 |

Business rules BR-001 to BR-021 are enforced in the domain layer (§4, §5) and
covered by T-004 to T-006, T-008 and T-009; section 7 names the tests per rule.

## 10. Design risks

| ID | Risk | Interim handling | What would change it |
|---|---|---|---|
| R-001 | D-004 leaves AC-N001-1 (restart persistence) and AC-014-1 (seed on a fresh start) unverified by automated tests. | Report both as known limitations in the test report and README, and verify them by hand at handoff, saying so explicitly. | Adding one integration test per criterion. |
| R-002 | D-004 leaves AC-N003-1 unverified: nothing proves a role check holds when the interface is bypassed, even though the design puts the check in the domain layer. | The design keeps all authorisation in domain functions so the guarantee is structural, and the gap is reported rather than claimed as covered. | One HTTP-level test invoking a restricted route with a member cookie. |
| R-003 | Prisma fixes the datasource provider in the schema, so PostgreSQL plus a SQLite fallback (D-002) means swapping the provider and keeping to features both support. | Stay inside the common subset: no range types, no exclusion constraints, no provider-specific SQL. Document the swap in the README. | Dropping the fallback, or generating two schema files. |
| R-004 | Derive-on-read expiry (D-005) means a pending request's stored state can lag until something reads it, so the database is not always current. | Availability and every decision path derive the state first, so no rule is ever evaluated against a stale state. | A startup sweep or a timer, if the lag proves visible. |
| R-005 | Server-rendered pages (D-003) give no separate API surface, so the quality stage cannot exercise rules over HTTP without form posts. | Accepted; the domain layer is tested directly instead. | Adding a small JSON API alongside the pages. |

No open `Q-` item exists in `REQUIREMENTS.md`, so no business question is
outstanding at the start of this stage.

## 11. Gate checklist

- [x] Every `REQ-` and `NFR-` in the specification is covered by a design element and by at least one task.
- [x] Every business rule (`BR-`) has a designed enforcement point.
- [x] Every design decision has an ID, the options considered, the choice, who decided, and why.
- [x] The engineers took the technology decisions; the AI chose nothing on its own. **Qualified:** D-001 to D-004 were chosen by the engineer. D-005 to D-008 were delegated to the AI with the instruction to keep them simple; each row records the delegation. The team accepted this at the gate.
- [x] No requirement was invented, changed, or dropped in this stage.
- [x] Every open `Q-` item is recorded as a design risk with the interim assumption the design relies on. No `Q-` item was open.
- [x] The booking state machine covers every state and transition in the specification, including who may trigger each and which dates it frees.
- [x] Role and ownership enforcement is designed for every action, not only in the interface.
- [x] Persistence across restart and the seeded users are designed.
- [x] The test strategy says how the acceptance criteria will be verified, including the 3 of 44 it cannot verify (R-001, R-002).
- [x] Tasks are small, ordered, and each names the requirement IDs it serves.
- [x] The product owner and the engineers have read the document and agree with it.

- **Gate result:** passed
- **Completed at (UTC, ISO 8601):** 2026-09-28T06:10:27Z
- **Confirmed by:** the team
- **Counts reported in pulse:** decisions=8, tasks=13

| Iteration | Scope | Gate | Completed (UTC) | Confirmed by | Counts |
|---|---|---|---|---|---|
| 1 | Initial design for REQ-001 to REQ-017: D-001 to D-008, T-001 to T-013, R-001 to R-005. | passed | 2026-09-28T06:10:27Z | the team | decisions=8, tasks=13 |
