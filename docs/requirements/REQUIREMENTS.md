# Requirements Specification

> Produced in the `requirements-elaboration` stage. Source: `docs/input/BUSINESS_REQUIREMENTS.md`.
> Every item should trace to the business input or to a team decision recorded under Assumptions.
> Replace the guidance in *italics* and the example rows with your own content.

## 1. User roles

*Who uses the system? What may each role do, and what must each role never be able to do?*

| Role | Description | Allowed | Not allowed |
|---|---|---|---|
| | | | |

## 2. Functional requirements

*What must the system do? One behaviour per requirement. Include the source.*

| ID | Requirement | Role(s) | Source (input section / assumption) |
|---|---|---|---|
| REQ-001 | | | |

## 3. Non-functional requirements

*Qualities and constraints: persistence, usability, performance, portability, maintainability, and so on.*

| ID | Requirement | Source |
|---|---|---|
| NFR-001 | | |

## 4. Business rules

*Rules the system must always enforce, regardless of interface or role.*

| ID | Rule | Source | Related requirements |
|---|---|---|---|
| BR-001 | | | |

## 5. Validation rules

*What input is accepted or rejected? What exactly happens when input is invalid?*

| ID | Applies to | Rule | Behaviour on failure |
|---|---|---|---|
| VAL-001 | | | |

## 6. Error scenarios

*What can go wrong? What should the user see or receive in each case?*

| ID | Scenario | Expected behaviour | Related IDs |
|---|---|---|---|
| ERR-001 | | | |

## 7. Edge cases

*Boundaries, limits, timing, and unusual but valid situations.*

| ID | Edge case | Expected behaviour | Related IDs |
|---|---|---|---|
| EC-001 | | | |

## 8. Security considerations

*What must be protected, from whom, and how will role restrictions be enforced even without real authentication?*

| ID | Consideration | Related IDs |
|---|---|---|
| SEC-001 | | |

## 9. Assumptions

*Every interpretation of an ambiguous statement, as decided by the team.*

| ID | Ambiguity (quote the input) | Options considered | Team decision | Decided by / why |
|---|---|---|---|---|
| A-001 | | | | |

## 10. Open questions

*Ambiguities the team has not resolved yet. Say how each one is handled until it is answered.*

| ID | Question | Impact | Interim handling | Status |
|---|---|---|---|---|
| Q-001 | | | | |

## 11. Acceptance criteria

*At least one testable criterion per requirement. Describe observable outcomes, not implementation (e.g. Given / When / Then).*

| Requirement | AC ID | Criterion |
|---|---|---|
| REQ-001 | AC-001-1 | |

## 12. Gate checklist

- [ ] Every statement in the business input maps to at least one requirement or business rule.
- [ ] Every requirement has an ID and at least one testable acceptance criterion.
- [ ] Every ambiguity found was decided by the team (assumption) or recorded (open question).
- [ ] No requirement was invented without a team decision.
- [ ] Roles and their permissions are explicit.
- [ ] Error scenarios and edge cases are listed.
- [ ] The document contains no design or technology decisions.
- [ ] The team has read the document and agrees with it.

- **Gate result:** passed / failed
- **Completed at (UTC, ISO 8601):**
- **Confirmed by:**
- **Counts reported in pulse:**
