> **READ-ONLY.** This is the business input for the challenge. Do not modify this file.
> Record your interpretations, assumptions, and open questions in `docs/requirements/REQUIREMENTS.md`.

# CabinConnect Lite — Business Requirements

## Background
A residential community owns one holiday cabin that its members share.
Bookings are currently managed through a group chat, which causes double
bookings, arguments, and no clear record of who has the cabin when. The
community wants a simple application to manage cabin bookings.

## Users
- **Member:** a resident who wants to use the cabin.
- **Administrator:** a committee member who oversees bookings.

## What the community needs
1. A member can see which dates the cabin is already booked, so they can plan a stay.
2. A member can request a booking for a date range.
3. A member can see their own bookings.
4. A member can cancel their own upcoming booking.
5. An administrator can see all bookings, including who made them.
6. An administrator can cancel any booking.

## Business rules
1. The cabin can only be used by one booking at a time. Bookings must never overlap.
2. A single booking can be at most 7 nights.
3. Bookings can only be made for future dates.
4. A member can hold at most 2 upcoming bookings at any time.
5. A booking that has already started cannot be cancelled by a member.
6. Cancelled bookings free the dates for others but should remain visible in the history.

## Constraints
- Use a technology stack of your team's choice.
- Login is out of scope. Provide a simple way to act as different seeded users
  (at least two members and one administrator). The application must still
  enforce what each role is allowed to do.
- Data must persist between restarts.

## Out of scope
Payments, email notifications, multiple cabins, multiple communities, real
authentication, and mobile apps.
