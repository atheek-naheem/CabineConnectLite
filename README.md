# CabinConnect Lite

> **Team:** complete every section marked *Completed at handoff* during the handoff stage. The final check
> is a fresh clone that uses only the commands written here.

## Getting started with the challenge

Read `CHALLENGE.md` first. Then:

1. Copy the environment template:

   ```text
   cp .env.example .env
   ```

2. Open `.env` and fill in `AIHUB_TEAM_KEY` (your team's ai-hub key) and
   `AIHUB_ACTOR` (your registered email). Never commit `.env`.
3. Check your setup without sending anything:

   ```text
   tools/pulse.sh requirements-elaboration started --dry-run
   ```

   On Windows PowerShell:

   ```text
   powershell -ExecutionPolicy Bypass -File tools\pulse.ps1 requirements-elaboration started --dry-run
   ```

   The output should end with "Setup looks complete". If it lists problems, fix
   them or ask the organizer.
4. In Claude Code, start the requirements-elaboration stage by asking it to use the
   `requirements-elaboration` skill.

---

## Project description

CabinConnect Lite manages bookings for a single holiday cabin shared by the
members of a residential community. It replaces a group chat that caused double
bookings and left no clear record of who has the cabin when.

Members can see which dates are already booked, request a booking for a date
range, see their own bookings, and cancel their own upcoming bookings.
Administrators (committee members) can see all bookings, including who made
them, and cancel any booking. The application enforces the booking rules: no
overlapping bookings, at most 7 nights per booking, future dates only, at most
2 upcoming bookings per member, and no member cancellation once a booking has
started. Cancelled bookings free their dates but stay visible in the history.

## Business requirements

Summary of [`docs/input/BUSINESS_REQUIREMENTS.md`](docs/input/BUSINESS_REQUIREMENTS.md),
which is the authoritative source. The elaborated specification is in
[`docs/requirements/REQUIREMENTS.md`](docs/requirements/REQUIREMENTS.md).

**Users**

- **Member:** a resident who wants to use the cabin.
- **Administrator:** a committee member who oversees bookings.

**What the community needs**

1. A member can see which dates the cabin is already booked, so they can plan a stay.
2. A member can request a booking for a date range.
3. A member can see their own bookings.
4. A member can cancel their own upcoming booking.
5. An administrator can see all bookings, including who made them.
6. An administrator can cancel any booking.

**Business rules**

1. The cabin can only be used by one booking at a time. Bookings must never overlap.
2. A single booking can be at most 7 nights.
3. Bookings can only be made for future dates.
4. A member can hold at most 2 upcoming bookings at any time.
5. A booking that has already started cannot be cancelled by a member.
6. Cancelled bookings free the dates for others but remain visible in the history.

**Constraints**

- Technology stack of the team's choice.
- No login. A simple way to act as different seeded users (at least two members
  and one administrator), while still enforcing what each role may do.
- Data persists between restarts.

## Chosen stack

*Completed at handoff: language, frameworks, storage, test tools, and where the decision is recorded in `docs/design/DESIGN.md`.*

## Prerequisites

*Completed at handoff: every tool and version needed on a fresh machine.*

## Install

```text
Completed at handoff: exact install command(s)
```

## Configure

*Completed at handoff: any configuration needed. Write "None" if there is none.*

## Run

```text
Completed at handoff: exact run command(s)
```

*Completed at handoff: how to open or use the running application, and how to act as each seeded user.*

## Test

```text
Completed at handoff: exact test command(s)
```

## Main scenarios

**Member**

1. Act as one of the seeded members.
2. View the booked dates and pick a free date range in the future of at most 7 nights.
3. Request the booking. It is rejected if it overlaps another booking, is longer
   than 7 nights, is not in the future, or would give the member more than 2
   upcoming bookings.
4. View your own bookings, including cancelled ones.
5. Cancel one of your upcoming bookings. Its dates become free for others, and
   it stays visible in your history. A booking that has already started cannot
   be cancelled.

**Administrator**

1. Act as the seeded administrator.
2. View all bookings, including which member made each one.
3. Cancel any booking. Its dates become free, and it stays visible in the history.

## Documentation

- Business input: [`docs/input/BUSINESS_REQUIREMENTS.md`](docs/input/BUSINESS_REQUIREMENTS.md)
- Requirements: [`docs/requirements/REQUIREMENTS.md`](docs/requirements/REQUIREMENTS.md)
- Design: [`docs/design/DESIGN.md`](docs/design/DESIGN.md)
- Test report: [`docs/testing/TEST_REPORT.md`](docs/testing/TEST_REPORT.md)
- AI log: [`AI-LOG.md`](AI-LOG.md)
- Challenge rules: [`CHALLENGE.md`](CHALLENGE.md)

## Known limitations

Out of scope by the business input: payments, email notifications, multiple
cabins, multiple communities, real authentication (seeded users are selected
instead of logging in), and mobile apps.
