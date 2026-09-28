# Requirements Specification

> Produced in the `requirements-elaboration` stage. Source: `docs/input/BUSINESS_REQUIREMENTS.md`.
> Every item traces to the business input or to a team decision recorded under Assumptions.

## 0. Vocabulary

These terms are used with exactly this meaning throughout the document.

| Term | Meaning | Source |
|---|---|---|
| Today | The current date in UTC. All date comparisons use whole calendar dates, never times of day. | A-014 |
| Check-in date | The first night of a stay. | A-002 |
| Check-out date | The departure date. It is not an occupied night, so another booking may begin on it. | A-002 |
| Nights | Check-out date minus check-in date, in days. | A-002 |
| Booking state | One of `Pending`, `Approved`, `Cancelled`, `Rejected`, `Expired`. | A-001, A-008 |
| Holding booking | A booking in state `Pending` or `Approved`. Holding bookings occupy their dates. | A-005 |
| In progress | An `Approved` booking where check-in ≤ today < check-out. | A-010 |
| Finished | An `Approved` booking where check-out ≤ today. | A-010 |
| Unfinished booking | A holding booking that is not finished. These count toward a member's booking limit. | A-006, A-010 |
| Owner | The member who submitted the booking. | Input: What the community needs #5 |
| Acting user | The seeded user currently selected; every action is evaluated against this user's role. | Input: Constraints |

## 1. User roles

| Role | Description | Allowed | Not allowed |
|---|---|---|---|
| Member | A resident who wants to use the cabin. | See which dates the cabin is unavailable within the bookable window; submit a booking request for a date range; see all of their own bookings with state; withdraw their own `Pending` request before its check-in date; cancel their own `Approved` booking before its check-in date. | See who made any other booking, or any detail of another member's booking; see the list of all bookings; approve or reject requests; cancel or withdraw a booking they do not own; cancel their own booking on or after its check-in date; change the dates of a submitted booking; submit a booking for another member. |
| Administrator | A committee member who oversees bookings. | See all bookings, including who made each one and its state; approve a `Pending` request; reject a `Pending` request, optionally recording a reason; cancel any booking that has not finished, including one in progress, optionally recording a reason. | Create a booking, for themselves or on behalf of a member; cancel a finished booking; change the dates of any booking; approve or reject a booking that is not `Pending`. |

## 2. Functional requirements

| ID | Requirement | Role(s) | Source (input section / assumption) |
|---|---|---|---|
| REQ-001 | Show which dates the cabin is unavailable, covering at least the bookable window (today through 90 days after today). Unavailable dates are shown without the owner's identity and without distinguishing `Pending` from `Approved`. | Member | Input: What #1; A-009; A-013 |
| REQ-002 | Submit a booking request for a check-in date and a check-out date. An accepted request is recorded in state `Pending` and immediately holds its dates. | Member | Input: What #2; A-001; A-005 |
| REQ-003 | Validate every booking request against all business rules (BR-001 to BR-006) at submission, and re-evaluate the current state of a booking on every state-changing action, rejecting the action if the state no longer permits it. | Member, Administrator | Input: Business rules #1–#4; A-001 |
| REQ-004 | List the acting member's own bookings in every state — `Pending`, `Approved` (including in progress and finished), `Cancelled`, `Rejected`, `Expired` — showing the dates, the state, and the reason if one was recorded. | Member | Input: What #3; Input: Business rules #6; A-016; A-017 |
| REQ-005 | Cancel an own `Approved` booking whose check-in date is after today. The booking moves to `Cancelled` and its dates are freed. | Member | Input: What #4; Input: Business rules #5 |
| REQ-006 | Withdraw an own `Pending` request whose check-in date is after today. The request moves to `Cancelled` and its dates are freed. | Member | A-007 |
| REQ-007 | List all bookings in every state, each with the owner's identity, the dates and the state. | Administrator | Input: What #5 |
| REQ-008 | Approve a `Pending` request. The booking moves to `Approved` and keeps holding its dates. | Administrator | A-001 |
| REQ-009 | Reject a `Pending` request, optionally recording a reason. The booking moves to `Rejected` and its dates are freed. | Administrator | A-001; A-017 |
| REQ-010 | Cancel any booking that has not finished, including one in progress, optionally recording a reason. The booking moves to `Cancelled` and its dates, from today onward, are freed. | Administrator | Input: What #6; A-011; A-017 |
| REQ-011 | Keep `Cancelled`, `Rejected` and `Expired` bookings visible in history while their dates are available to other bookings. | Member, Administrator | Input: Business rules #6; A-001; A-008 |
| REQ-012 | Move a `Pending` request to `Expired` once its check-in date has arrived without an administrator decision, freeing its dates. No administrator action is possible on it afterwards. | — (system) | A-008 |
| REQ-013 | Let a person select which seeded user to act as, and enforce that user's role permissions on every action. | Member, Administrator | Input: Constraints |
| REQ-014 | Provide exactly two seeded members and one seeded administrator, available without any setup step on first start. | — (system) | Input: Constraints; A-018 |

## 3. Non-functional requirements

| ID | Requirement | Source |
|---|---|---|
| NFR-001 | All bookings, their states and recorded reasons survive a restart of the application. | Input: Constraints ("Data must persist between restarts") |
| NFR-002 | The technology stack is the team's choice; this document imposes none. | Input: Constraints |
| NFR-003 | Role permissions are enforced by the application's own logic for every action, not only by hiding controls in the user interface. | Input: Constraints ("The application must still enforce what each role is allowed to do") |
| NFR-004 | Switching between seeded users is simple and needs no credentials or configuration. | Input: Constraints ("a simple way to act as different seeded users") |
| NFR-005 | The following are outside the scope of this specification: payments, email notifications, multiple cabins, multiple communities, real authentication, and mobile apps. | Input: Out of scope |
| NFR-006 | Every rejection of an action states which rule was violated, in terms a resident understands. | Input: Background ("double bookings, arguments"); A-001 |

## 4. Business rules

| ID | Rule | Source | Related requirements |
|---|---|---|---|
| BR-001 | Two holding bookings (`Pending` or `Approved`) may never occupy the same night. The cabin is used by at most one booking at a time. | Input: Business rules #1; A-005 | REQ-002, REQ-003, REQ-008 |
| BR-002 | A booking is at most 7 nights: check-out minus check-in ≤ 7 days. | Input: Business rules #2; A-002 | REQ-002, REQ-003 |
| BR-003 | A booking is at least 1 night: check-out is strictly after check-in. | A-015 | REQ-002, REQ-003 |
| BR-004 | A booking's check-in date is today or later. Dates before today are never bookable. | Input: Business rules #3; A-003; A-014 | REQ-002, REQ-003 |
| BR-005 | A booking's check-out date is at most 90 days after today. | A-013 | REQ-002, REQ-003 |
| BR-006 | A member has at most 2 unfinished bookings at any time. `Pending` requests and `Approved` bookings both count, and an in-progress booking still counts. | Input: Business rules #4; A-006; A-010 | REQ-002, REQ-003 |
| BR-007 | A member cannot cancel a booking on or after its check-in date. | Input: Business rules #5 | REQ-005, REQ-006 |
| BR-008 | An administrator can cancel any booking that has not finished, including one in progress. A finished booking cannot be cancelled by anyone. | Input: What #6; A-011 | REQ-010 |
| BR-009 | `Cancelled`, `Rejected` and `Expired` bookings free their dates for other bookings and remain in history permanently. No booking is ever deleted. | Input: Business rules #6; A-008 | REQ-004, REQ-007, REQ-011 |
| BR-010 | An administrator never creates a booking. Only a member creates bookings, and only for themselves. | A-004 | REQ-002 |
| BR-011 | A booking's dates are fixed once submitted. Changing dates means cancelling and submitting a new request. | A-012 | REQ-002, REQ-005 |
| BR-012 | The owner of a booking is the member who submitted it, and it never changes. | Input: What #5; A-004 | REQ-004, REQ-005, REQ-007 |
| BR-013 | A booking may begin on the check-out date of another booking; that date is not a shared night. | A-002 | BR-001, REQ-002 |
| BR-014 | Whether a date is past, today or future, and whether a booking has started or finished, is decided against the current UTC date. | A-014 | BR-004, BR-005, BR-007, BR-008 |
| BR-015 | A `Pending` request that reaches its check-in date without a decision becomes `Expired` and is never approvable. | A-008 | REQ-012 |
| BR-016 | Only a `Pending` booking can be approved or rejected, and only an `Approved` unfinished booking can be cancelled by an administrator. Each booking reaches a terminal state (`Cancelled`, `Rejected`, `Expired`, or finished) at most once. | A-001; A-011 | REQ-003, REQ-008, REQ-009, REQ-010 |

## 5. Validation rules

| ID | Applies to | Rule | Behaviour on failure |
|---|---|---|---|
| VAL-001 | Booking request | Check-in and check-out are both supplied and are valid calendar dates. | Request refused; the missing or unparseable field is named. No booking is created. |
| VAL-002 | Booking request | Check-out is strictly after check-in (BR-003). | Request refused, stating a booking must cover at least one night. |
| VAL-003 | Booking request | Check-out minus check-in ≤ 7 days (BR-002). | Request refused, stating the 7-night maximum and the requested length. |
| VAL-004 | Booking request | Check-in ≥ today, UTC (BR-004). | Request refused, stating bookings cannot start in the past. |
| VAL-005 | Booking request | Check-out ≤ today + 90 days, UTC (BR-005). | Request refused, stating the 90-day booking horizon. |
| VAL-006 | Booking request | No night in the range is occupied by a holding booking (BR-001). | Request refused, stating that the dates are not available. No identity of the conflicting booking's owner is disclosed. |
| VAL-007 | Booking request | The acting member has fewer than 2 unfinished bookings (BR-006). | Request refused, stating the limit of 2 and that a booking must be cancelled or finished first. |
| VAL-008 | Booking request | The acting user's role is Member (BR-010). | Request refused as not permitted for the acting role. |
| VAL-009 | Member cancellation (REQ-005, REQ-006) | The booking exists, is owned by the acting member, is `Pending` or `Approved`, and its check-in date is after today (BR-007, BR-012). | Refused, stating which condition failed: not the member's booking, already in a terminal state, or already started. State is unchanged. |
| VAL-010 | Approve / reject (REQ-008, REQ-009) | The acting user's role is Administrator and the booking is `Pending` (BR-016). | Refused, stating the acting role is not permitted or reporting the booking's current state. State is unchanged. |
| VAL-011 | Administrator cancellation (REQ-010) | The acting user's role is Administrator, the booking is `Approved`, and check-out is after today (BR-008). | Refused, stating the acting role is not permitted or that a finished booking cannot be cancelled. State is unchanged. |
| VAL-012 | Reason on reject / cancel | Optional. If supplied, it is recorded verbatim and shown to the owner; if omitted, the state change is recorded without one. | Not applicable; an absent reason is valid. See Q-001 for length limits. |
| VAL-013 | Acting user selection (REQ-013) | The selected user is one of the seeded users. | Action refused; no booking data is read or written on behalf of an unknown user. |
| VAL-014 | Any booking read | A member's request for booking detail is limited to bookings they own (BR-012, A-009). | Refused without revealing whether the booking exists or who owns it. |

## 6. Error scenarios

| ID | Scenario | Expected behaviour | Related IDs |
|---|---|---|---|
| ERR-001 | A member requests dates that overlap a `Pending` or `Approved` booking. | Refused with a dates-unavailable message; nothing is created; the other booking is untouched and its owner is not named. | BR-001, VAL-006 |
| ERR-002 | A member requests 8 or more nights. | Refused, stating the 7-night maximum. | BR-002, VAL-003 |
| ERR-003 | A member requests a check-in date before today. | Refused, stating bookings cannot start in the past. | BR-004, VAL-004 |
| ERR-004 | A member requests a check-out date more than 90 days after today. | Refused, stating the 90-day horizon. | BR-005, VAL-005 |
| ERR-005 | A member with 2 unfinished bookings submits a third request. | Refused, stating the limit of 2. | BR-006, VAL-007 |
| ERR-006 | A member tries to cancel their own booking on or after its check-in date. | Refused, stating a started booking cannot be cancelled by a member; the member is told an administrator can do it. | BR-007, VAL-009 |
| ERR-007 | A member tries to cancel or withdraw a booking owned by someone else. | Refused as not permitted, revealing nothing about the booking or its owner. | BR-012, VAL-009, VAL-014 |
| ERR-008 | A member tries to approve, reject, or list all bookings. | Refused as not permitted for the acting role; no booking data of other members is returned. | NFR-003, VAL-008, VAL-010 |
| ERR-009 | An administrator tries to create a booking. | Refused, stating administrators do not create bookings. | BR-010, VAL-008 |
| ERR-010 | An administrator approves or rejects a request that is no longer `Pending` — already withdrawn, expired, or already decided. | Refused, reporting the booking's current state; the state is unchanged. | BR-015, BR-016, VAL-010 |
| ERR-011 | An administrator tries to cancel a booking whose check-out date has passed. | Refused, stating a finished booking cannot be cancelled. | BR-008, VAL-011 |
| ERR-012 | Someone tries to cancel a booking that is already `Cancelled`, `Rejected` or `Expired`. | Refused, reporting the current state; history is not altered and no duplicate state change is recorded. | BR-009, BR-016 |
| ERR-013 | Two members submit overlapping requests at the same instant. | Exactly one request is accepted; the other is refused with the dates-unavailable message. No overlap is ever stored. | BR-001, VAL-006 |
| ERR-014 | A booking request is submitted with a malformed or missing date. | Refused, naming the offending field; nothing is created. | VAL-001 |
| ERR-015 | An action is attempted with no acting user selected, or an unknown one. | Refused; the person is asked to select a seeded user. | VAL-013 |
| ERR-016 | A member acts on a view that has become stale — for example the dates were taken, or the date rolled over so the booking has now started. | The action is re-validated at the moment it is performed and refused if a rule now fails; the refusal explains what changed. | REQ-003, BR-014 |

## 7. Edge cases

| ID | Edge case | Expected behaviour | Related IDs |
|---|---|---|---|
| EC-001 | Check-in date is today. | Accepted. | BR-004, A-003 |
| EC-002 | Exactly 7 nights. | Accepted. 8 nights is refused. | BR-002 |
| EC-003 | Check-out equals check-in (zero nights). | Refused. | BR-003 |
| EC-004 | A request starts on the check-out date of an existing holding booking. | Accepted; same-day turnover is not an overlap. | BR-013 |
| EC-005 | Check-out is exactly 90 days after today. | Accepted. 91 days is refused. | BR-005 |
| EC-006 | A member holding 2 unfinished bookings cancels one. | A slot is freed at once and a new request is accepted. | BR-006, REQ-005 |
| EC-007 | A member holds one in-progress booking and one future booking. | A third request is refused, because an in-progress booking still counts. | BR-006, A-010 |
| EC-008 | Both of a member's unfinished bookings are `Pending`. | A third request is refused; pending requests count toward the limit. | BR-006, A-006 |
| EC-009 | A member's new request overlaps their own `Pending` request. | Refused on the overlap rule, exactly as for another member's booking. | BR-001 |
| EC-010 | A booking is cancelled, rejected or expired. | Its dates become immediately available to any member, including the same member. | BR-009, REQ-011 |
| EC-011 | The UTC date rolls over onto a `Pending` request's check-in date. | The request becomes `Expired` from that moment; a subsequent approval attempt is refused. | BR-015, REQ-012 |
| EC-012 | An administrator cancels a booking that is in progress. | Accepted. Nights from today onward are freed; the booking remains in history as `Cancelled`. | BR-008, REQ-010 |
| EC-013 | The UTC date rolls over onto an `Approved` booking's check-in date. | The member can no longer cancel it; only an administrator can. | BR-007, BR-008 |
| EC-014 | A member's booking finishes (check-out ≤ today). | It stops counting toward the limit, stays visible in the member's own list, and can no longer be cancelled by anyone. | BR-006, BR-008, REQ-004 |
| EC-015 | Two adjacent bookings share a date, one checking out and one checking in. | Both are valid and both are shown; the shared date is unavailable for a new check-in only if it is an occupied night of some booking. | BR-013, REQ-001 |
| EC-016 | Every date in the visible window is booked. | The availability view clearly shows no dates are free rather than appearing empty or broken. | REQ-001, NFR-006 |
| EC-017 | The person switches acting user midway through a task. | Subsequent actions are evaluated against the newly selected user's role and ownership; nothing carries over from the previous user. | REQ-013, NFR-003 |
| EC-018 | A request spans the end of the 90-day window with its check-in inside it. | Refused, because the whole stay must fall within the horizon (check-out ≤ today + 90 days). | BR-005, VAL-005 |

## 8. Security considerations

| ID | Consideration | Related IDs |
|---|---|---|
| SEC-001 | Every action is authorised against the acting user's role and, for member actions, against ownership of the booking, in the application's own logic. Hiding a control in the interface is never the only barrier. | NFR-003, VAL-008 to VAL-011 |
| SEC-002 | A member never learns the identity of another member's booking, nor its state or reason; refusals for other members' bookings do not disclose whether the booking exists. | A-009, VAL-014, ERR-007 |
| SEC-003 | Acting-user switching is deliberately unauthenticated, so anyone using the application can act as the administrator. This is accepted only because login is out of scope, and the application is not fit for public deployment as a result. It is recorded so it is never mistaken for an oversight. | Input: Constraints; Input: Out of scope; REQ-013 |
| SEC-004 | All input is validated by the application before it is acted on, and free text such as a recorded reason is treated as untrusted when it is stored and shown. | VAL-001, VAL-012 |
| SEC-005 | No booking is ever destroyed, so history cannot be silently rewritten; state changes only move a booking forward to a terminal state. | BR-009, BR-016 |
| SEC-006 | Seed data contains no real personal data, and no secrets or credentials are committed to the repository. | Input: Constraints; `CLAUDE.md` |

## 9. Assumptions

| ID | Ambiguity (quote the input) | Options considered | Team decision | Decided by / why |
|---|---|---|---|---|
| A-001 | "A member can **request** a booking for a date range." | (a) Confirmed immediately on submission; (b) pending until an administrator approves or rejects it. | (b) A booking is created `Pending` and an administrator approves or rejects it. | Neema (product owner), 2026-09-28. The committee "oversees bookings", so the request is a request in the literal sense. |
| A-002 | "A single booking can be at most 7 nights" together with "Bookings must never overlap." | (a) Check-in / check-out, nights = check-out − check-in, check-out day free for the next booking; (b) inclusive nights, both end dates occupied. | (a) Check-in / check-out semantics; a 7-night stay spans 8 calendar dates and same-day turnover is allowed. | Neema (product owner), 2026-09-28. Matches how a cabin stay is normally counted. |
| A-003 | "Bookings can only be made for future dates." | (a) Earliest start is tomorrow; (b) a stay starting today is allowed. | (b) Check-in may be today; only dates before today are refused. | Neema (product owner), 2026-09-28. |
| A-004 | The input lists only viewing and cancelling for the administrator and never says whether one may book. | (a) Oversight only, no booking; (b) administrator is also a resident and may book; (c) administrator may book on behalf of members. | (a) Administrators never create bookings. | Neema (product owner), 2026-09-28. Keeps permissions to exactly what the input states. |
| A-005 | "The cabin can only be used by one booking at a time. Bookings must never overlap" — with a pending state, does pending occupy dates? | (a) Pending holds the dates, first request wins; (b) competing pending requests allowed, approval auto-rejects the others. | (a) A `Pending` request holds its dates; a later overlapping request is refused at submission. | Neema (product owner), 2026-09-28. |
| A-006 | "A member can hold at most 2 upcoming bookings at any time" — does a pending request count? | (a) Pending and approved both count; (b) only approved count. | (a) Both count, so a member has at most 2 in flight. | Neema (product owner), 2026-09-28. |
| A-007 | The input does not say whether a member may withdraw a request before it is decided. | (a) Member may withdraw a pending request before its check-in date; (b) only an administrator may reject it. | (a) A member may withdraw their own `Pending` request. | Neema (product owner), 2026-09-28. |
| A-008 | The input does not say what happens to an undecided request when its dates arrive. | (a) It expires automatically and frees the dates; (b) it stays pending and keeps holding the dates. | (a) It becomes `Expired`, frees its dates, and stays in history. | Neema (product owner), 2026-09-28. Prevents undecided requests from blocking dates forever. |
| A-009 | "A member can see which dates the cabin is already booked" versus "An administrator can see all bookings, **including who made them**." | (a) Dates only, no names, no state; (b) dates with state but no names; (c) full details for members too. | (a) Members see unavailable dates only, with no owner identity and no distinction between pending and approved. | Neema (product owner), 2026-09-28. Owner identity stays an administrator privilege. |
| A-010 | "at most 2 **upcoming** bookings" — does a stay that has started still count? | (a) Only not-yet-started bookings count; (b) anything not yet finished counts. | (b) An in-progress booking still occupies one of the 2 slots. | Neema (product owner), 2026-09-28. |
| A-011 | "An administrator can cancel **any** booking." | (a) Any booking not yet finished, including in progress; (b) truly any, including finished ones; (c) only not-yet-started ones. | (a) Any booking that has not finished, including one in progress; finished bookings cannot be cancelled. | Neema (product owner), 2026-09-28. History of completed stays stays intact. |
| A-012 | The input never mentions changing a booking. | (a) No edit; cancel and request again; (b) dates editable before the stay starts. | (a) There is no edit. | Neema (product owner), 2026-09-28. Nothing invented beyond the input. |
| A-013 | The input sets no limit on how far ahead a booking may be made. | (a) No limit; (b) 12 months ahead; (c) 90 days ahead. | (c) Check-out must be within 90 days of today. | Neema (product owner), 2026-09-28. |
| A-014 | The input defines no times or timezone for "future dates" or "already started". | (a) Whole dates in one fixed community timezone; (b) whole dates against the current UTC date. | (b) Whole calendar dates evaluated against the current UTC date. | Neema (product owner), 2026-09-28. |
| A-015 | The input gives a maximum of 7 nights but no minimum. | (a) At least 1 night, equal dates refused; (b) zero-night day visits allowed. | (a) At least 1 night. | Neema (product owner), 2026-09-28. |
| A-016 | "A member can see their own bookings" together with "Cancelled bookings ... should remain visible in the history." | (a) All states, with the state shown; (b) upcoming only. | (a) A member sees their own bookings in every state. | Neema (product owner), 2026-09-28. |
| A-017 | The input does not say whether a rejection or an administrator cancellation carries an explanation. | (a) No reason recorded; (b) an optional reason recorded and visible to the owner. | (b) An optional reason, shown to the booking's owner. Notifications remain out of scope. | Neema (product owner), 2026-09-28. |
| A-018 | "at least two members and one administrator" must be seeded. | (a) Exactly 2 members and 1 administrator; (b) 3 members and 1 administrator. | (a) Exactly 2 members and 1 administrator. | Neema (product owner), 2026-09-28. |

## 10. Open questions

| ID | Question | Impact | Interim handling | Status |
|---|---|---|---|---|
| Q-001 | Are there limits on the optional reason recorded with a rejection or an administrator cancellation — maximum length, or required rather than optional in some case? | Affects VAL-012 and what the owner sees in REQ-004. Low: only the reason field. | Treated as optional free text, recorded verbatim, with no enforced maximum length. | Open |
| Q-002 | Should history record which user rejected or cancelled a booking, and when? The input asks only that cancelled bookings stay visible. | Affects REQ-004, REQ-007 and BR-009. Medium: adds data to every state change if wanted. | Not recorded; only the resulting state and the optional reason are kept. | Open |

## 11. Acceptance criteria

| Requirement | AC ID | Criterion |
|---|---|---|
| REQ-001 | AC-001-1 | Given an `Approved` booking from 10 to 12 June and today is 1 June, when a member views availability, then 10 and 11 June are shown unavailable and 12 June is shown available. |
| REQ-001 | AC-001-2 | Given a `Pending` request held by another member, when a member views availability, then its nights are shown unavailable with no owner name and no indication that it is pending rather than approved. |
| REQ-001 | AC-001-3 | Given today is 1 June, when a member views availability, then at least every date from 1 June through 30 August (today + 90 days) is represented. |
| REQ-002 | AC-002-1 | Given no conflicting booking and a member with fewer than 2 unfinished bookings, when the member submits check-in 10 June and check-out 13 June, then a booking is recorded in state `Pending`, owned by that member, for 3 nights. |
| REQ-002 | AC-002-2 | Given the request of AC-002-1 was accepted, when any member views availability, then 10, 11 and 12 June are unavailable. |
| REQ-003 | AC-003-1 | Given a request that breaks any of BR-001 to BR-006, when it is submitted, then no booking is created and the response names the rule that was broken. |
| REQ-003 | AC-003-2 | Given a `Pending` request that a member withdrew, when an administrator approves it, then the action is refused and the booking remains `Cancelled`. |
| REQ-004 | AC-004-1 | Given a member owns one `Pending`, one `Approved` future, one finished, one `Cancelled`, one `Rejected` and one `Expired` booking, when they view their own bookings, then all six appear with their dates and state. |
| REQ-004 | AC-004-2 | Given an administrator rejected the member's request with the reason "cabin closed for repairs", when the member views their own bookings, then that reason is shown against the `Rejected` booking. |
| REQ-004 | AC-004-3 | Given another member owns a booking, when a member views their own bookings, then that booking does not appear. |
| REQ-005 | AC-005-1 | Given an `Approved` booking owned by the acting member with check-in after today, when the member cancels it, then its state becomes `Cancelled` and its nights become available to other members. |
| REQ-005 | AC-005-2 | Given an `Approved` booking owned by the acting member with check-in equal to today, when the member cancels it, then the action is refused and the booking stays `Approved`. |
| REQ-006 | AC-006-1 | Given a `Pending` request owned by the acting member with check-in after today, when the member withdraws it, then its state becomes `Cancelled`, its dates are freed, and it still appears in their own list. |
| REQ-007 | AC-007-1 | Given bookings owned by both seeded members in several states, when the administrator views all bookings, then every booking appears with its owner's name, dates and state. |
| REQ-008 | AC-008-1 | Given a `Pending` request, when the administrator approves it, then its state becomes `Approved`, its dates remain unavailable, and the owner sees it as approved. |
| REQ-008 | AC-008-2 | Given an `Approved` booking, when the administrator approves it again, then the action is refused and the state is unchanged. |
| REQ-009 | AC-009-1 | Given a `Pending` request, when the administrator rejects it with a reason, then its state becomes `Rejected`, the reason is stored, and its nights become available to other members. |
| REQ-009 | AC-009-2 | Given a `Pending` request, when the administrator rejects it without a reason, then the rejection succeeds and no reason is stored. |
| REQ-010 | AC-010-1 | Given an `Approved` booking with check-in after today, when the administrator cancels it, then its state becomes `Cancelled` and its dates are freed. |
| REQ-010 | AC-010-2 | Given an `Approved` booking with check-in ≤ today < check-out, when the administrator cancels it, then the cancellation succeeds and the nights from today onward become available. |
| REQ-010 | AC-010-3 | Given an `Approved` booking with check-out ≤ today, when the administrator cancels it, then the action is refused and the booking stays as it was. |
| REQ-011 | AC-011-1 | Given a booking was cancelled, when another member requests the same dates, then the request is accepted, and the cancelled booking is still listed in history for its owner and for the administrator. |
| REQ-012 | AC-012-1 | Given a `Pending` request with check-in 10 June and no decision, when the current UTC date becomes 10 June, then its state is `Expired`, its dates are available, and approving or rejecting it is refused. |
| REQ-012 | AC-012-2 | Given the expired request of AC-012-1, when its owner views their own bookings, then it appears as `Expired`. |
| REQ-013 | AC-013-1 | Given the acting user is a member, when any administrator-only action is attempted, then it is refused and no data belonging to other members is returned. |
| REQ-013 | AC-013-2 | Given the acting user is the administrator, when a booking creation is attempted, then it is refused. |
| REQ-013 | AC-013-3 | Given a member owns a booking, when the acting user is switched to the other member and that member attempts to cancel it, then the action is refused. |
| REQ-014 | AC-014-1 | Given a freshly started application with no prior data, when the user list is inspected, then exactly two members and one administrator exist and each can be selected as the acting user. |
| NFR-001 | AC-N001-1 | Given bookings in several states and a recorded rejection reason, when the application is stopped and started again, then every booking, state and reason is unchanged. |
| NFR-003 | AC-N003-1 | Given an administrator-only or ownership-restricted action is invoked directly, bypassing the user interface, when the acting user lacks the permission, then the action is refused and nothing is changed. |
| NFR-006 | AC-N006-1 | Given each of ERR-001 to ERR-006, when the action is refused, then the message names the specific rule that blocked it rather than a generic failure. |

## 12. Gate checklist

- [x] Every statement in the business input maps to at least one requirement or business rule.
- [x] Every requirement has an ID and at least one testable acceptance criterion.
- [x] Every ambiguity found was decided by the team (assumption) or recorded (open question).
- [x] No requirement was invented without a team decision.
- [x] Roles and their permissions are explicit.
- [x] Error scenarios and edge cases are listed.
- [x] The document contains no design or technology decisions.
- [x] The team has read the document and agrees with it.

- **Gate result:** passed
- **Completed at (UTC, ISO 8601):** 2026-09-28T05:22:45Z
- **Confirmed by:** Neema, product owner
- **Counts reported in pulse:** requirements=14, assumptions=18, open_questions=2

### Traceability of the business input

Every statement in `docs/input/BUSINESS_REQUIREMENTS.md` and where it is covered.

| Input statement | Covered by |
|---|---|
| Background: double bookings, arguments, no clear record | BR-001, REQ-007, REQ-011, NFR-006 |
| Users: Member | Role table, REQ-001 to REQ-006 |
| Users: Administrator | Role table, REQ-007 to REQ-010 |
| What #1: member sees booked dates | REQ-001, A-009 |
| What #2: member requests a booking for a date range | REQ-002, A-001, A-002 |
| What #3: member sees their own bookings | REQ-004, A-016 |
| What #4: member cancels their own upcoming booking | REQ-005, REQ-006, BR-007 |
| What #5: administrator sees all bookings including who made them | REQ-007 |
| What #6: administrator cancels any booking | REQ-010, BR-008, A-011 |
| Rule 1: one booking at a time, never overlapping | BR-001, BR-013, VAL-006, ERR-001, ERR-013 |
| Rule 2: at most 7 nights | BR-002, VAL-003, ERR-002, EC-002 |
| Rule 3: future dates only | BR-004, VAL-004, ERR-003, EC-001 |
| Rule 4: at most 2 upcoming bookings | BR-006, VAL-007, ERR-005, EC-006 to EC-008 |
| Rule 5: started booking not cancellable by a member | BR-007, VAL-009, ERR-006, EC-013 |
| Rule 6: cancelled bookings free dates, stay in history | BR-009, REQ-011, EC-010 |
| Constraint: technology stack of the team's choice | NFR-002 |
| Constraint: login out of scope, act as seeded users, roles still enforced | REQ-013, REQ-014, NFR-003, NFR-004, SEC-001, SEC-003 |
| Constraint: data persists between restarts | NFR-001 |
| Out of scope list | NFR-005 |
