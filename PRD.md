# PRD

## 1. Product Summary

`Rental-Report` is an iPhone app that helps people create room-by-room rental inspection reports with photos, notes, signatures, and a PDF export. The product is built for one narrow job: documenting property condition at move-in and move-out so users can reduce deposit disputes and keep a clean evidence trail.

## 2. Market Positioning

- Target market: `United States` first
- Expansion markets: `Canada`, `United Kingdom`, `Australia`, `New Zealand`, `Ireland`, `Singapore`
- Core acquisition: `App Store search`
- Monetization: `one-time paid download`
- Product stance: `simple utility`, not `property management platform`

## 3. Target Users

- Independent landlords managing `1-20` units
- Small property managers who need a fast field tool
- Airbnb and short-term rental hosts handling turnovers
- Tenants who want a timestamped move-in or move-out record

Primary buyer for v1: `independent landlords and hosts`

Reason:

- Higher repeat usage than tenants
- Better willingness to pay
- Still broad enough to capture tenant search traffic through metadata

## 4. Jobs To Be Done

- Help me inspect a rental unit room by room.
- Let me attach photos and short notes as I walk through.
- Help me compare move-in and move-out condition.
- Generate a PDF I can send, save, or print.
- Capture signatures so the report feels complete and credible.

## 5. Product Goals

- Ship an MVP a solo developer can complete in `4-6 weeks`.
- Rank for long-tail App Store queries around `rental inspection`, `move-in checklist`, `move-out report`, and `security deposit`.
- Make a one-time paid model work at `US$4.99`.
- Keep v1 lightweight with no backend dependency.

## 6. Non-Goals

- No tenant portal
- No rent collection
- No maintenance ticketing
- No lease signing
- No multi-user cloud collaboration
- No subscription in v1
- No legal advice workflow

## 7. Competitive Angle

The niche already has larger products and heavier business tools. `Rental-Report` wins by being:

- faster than property management software
- clearer than a blank notes or photos app
- cheaper and simpler than inspection SaaS
- more trustworthy than ad-filled free utilities

The product promise is narrow:

`Finish a move-in or move-out inspection in minutes and walk away with a clean PDF report.`

## 8. Core User Flows

### 8.1 Start A New Inspection

- Choose inspection type:
  - `Move-In`
  - `Move-Out`
  - `Routine`
- Enter property name
- Optional address
- Optional tenant name
- Inspection date defaults to current date

### 8.2 Room-By-Room Walkthrough

- Start with preloaded room templates:
  - Entry
  - Living Room
  - Kitchen
  - Bedroom
  - Bathroom
  - Hallway
  - Laundry
  - Garage
  - Exterior
- Add or remove rooms
- For each room:
  - add overview photo
  - add issue photos
  - select condition status
  - write short notes

### 8.3 Condition Capture

For each room item, support:

- `Good`
- `Needs Cleaning`
- `Worn`
- `Damaged`
- `Missing`

Optional fields:

- note
- photo
- severity tag

### 8.4 Signatures

- Landlord / manager signature
- Tenant / occupant signature
- Optional skip if unavailable

### 8.5 PDF Export

- Generate a clean PDF with:
  - cover page
  - property info
  - inspection type
  - date
  - room sections
  - photos
  - notes
  - signatures
- Share via iOS share sheet

### 8.6 Inspection History

- Save completed reports locally
- Reopen completed inspections as read-only
- Duplicate a move-in report into a move-out draft

## 9. v1 Feature Scope

### 9.1 Onboarding

- short first-run explanation
- no account
- no sign-up
- no tutorial wall

### 9.2 Property Template

- save one or more properties locally
- property nickname
- optional address
- optional unit number

### 9.3 Checklist Template

- built-in room list
- built-in common check items:
  - walls
  - floors
  - doors
  - windows
  - lights
  - outlets
  - appliances
  - smoke detectors
  - plumbing fixtures

### 9.4 Photos

- camera capture
- photo library import
- multiple photos per room

### 9.5 Notes

- short free text note per room
- short note per issue

### 9.6 Condition Summary

- auto-count flagged issues
- show total rooms completed
- show missing signatures before export

### 9.7 PDF Generation

- export locally
- share by email, message, or files app

### 9.8 Settings

- date format
- default report title format
- include or hide empty checklist items

## 10. v1.1 Candidates

- before/after photo comparison
- cloud backup
- CSV export
- reminder for upcoming move-out inspections
- branded report logo
- iPad layout optimization

## 11. UX Principles

- one-handed, field-friendly flow
- large tap targets for on-site use
- minimal typing
- always show progress through the inspection
- no cluttered dashboards

## 12. Core Screens

- Welcome
- Inspection Type Picker
- Property Picker / Create Property
- Room List
- Room Detail
- Add Photo
- Signatures
- Export Preview
- Inspection History
- Settings

## 13. Monetization

- Model: `paid upfront`
- Launch price: `US$4.99`
- Why:
  - low enough for impulse purchase from search traffic
  - high enough to position as a serious utility
  - safer than subscription for a narrow solo-built tool

Future pricing test:

- keep `US$4.99` at launch
- test `US$5.99` after initial review base if conversion remains healthy

## 14. Success Metrics

- App Store page conversion rate
- Paid downloads from U.S. storefront
- PDF export rate
- Percentage of inspections completed after start
- Review count and average rating
- Share action rate

## 15. Technical Assumptions

- iPhone only in v1
- SwiftUI
- local database or file storage only
- no login
- no backend
- PDF generation on device

## 16. Compliance Assumptions

- target age rating: `4+`
- no public user-generated content
- no health or finance claims
- no legal advice claims
- if no analytics or remote services are added, App Privacy can likely remain `Data Not Collected`

## 17. Product Risks

- strong competition from free landlord platforms
- weak differentiation if screenshots look generic
- App Review risk if copy implies guaranteed legal protection

Mitigation:

- keep copy factual
- emphasize `documentation` and `organization`, not legal outcomes
- use screenshots that clearly show `room-by-room`, `photos`, `signatures`, and `PDF`
