# App Store Connect Fields

This file is the practical base template for creating the iOS app record and preparing the first version submission.

## 1. Create App Record

- Platform: `iOS`
- Name: `Rental-Report`
- Primary Language: `English (U.S.)`
- Bundle ID: `com.yourstudio.rentalreport`
- SKU: `rental-report-ios`
- User Access: `Full Access` or restricted by team policy

Note:

- `Bundle ID` and `SKU` cannot be changed casually later. Replace `yourstudio` with your real team namespace before creating the record.

## 2. App Information

- Subtitle: `Move-In Inspection Checklist`
- Primary Category: `Business`
- Secondary Category: `Productivity`
- Content Rights: `No, it does not contain, show, or access third-party content`
- Age Rating target: `4+`
- Copyright: `© 2026 Your Studio Name`
- Privacy Policy URL: `https://your-domain.com/rental-report/privacy`
- Support URL: `https://your-domain.com/rental-report/support`
- Marketing URL: `https://your-domain.com/rental-report`

## 3. Pricing And Availability

- Price: `US$4.99`
- Base Country or Region: `United States`
- Initial countries:
  - `United States`
  - `Canada`
  - `United Kingdom`
  - `Australia`
  - `New Zealand`
  - `Ireland`
  - `Singapore`
- Release option: `Manually release this version`

Why this setup:

- English-only metadata is sufficient for these storefronts at launch.
- U.S. is the base market and the main ASO target.
- Manual release gives time to verify screenshots and search appearance after approval.

## 4. Version Metadata

- App Name: `Rental-Report`
- Subtitle: `Move-In Inspection Checklist`
- Promotional Text:
  - `Create room-by-room rental inspection reports with photos, notes, signatures, and a shareable PDF. No account. No subscription. Built for fast on-site walkthroughs.`
- Description:
  - use the description block from [ASO.md](/Users/cc/StudioProjects/Rental-Report/ASO.md)
- Keywords:
  - `landlord,tenant,property,deposit,walkthrough,photos,signature,pdf,damage,apartment,moveout`
- What's New:
  - `Initial release.`

## 5. App Review Information

- First Name: `[app review contact first name]`
- Last Name: `[app review contact last name]`
- Phone Number: `[app review contact phone]`
- Email Address: `[app review contact email]`
- Demo Account Required: `No`
- Notes:
  - `This app is a rental inspection utility for iPhone. No login, payment account, or external hardware is required to review the app. Users can create room-by-room reports, capture photos and notes, collect signatures, and export a polished PDF summary.`

## 6. App Privacy

Recommended target for MVP:

- `Data Not Collected`

This only stays true if:

- no analytics SDK is added
- no crash SDK collecting device-linked data is added
- no login or account system is added
- no remote sync is added

If the implementation changes, App Privacy must be updated with it.

## 7. Export Compliance

Expected answer for MVP:

- likely `No` if the app only uses standard Apple system encryption and no special cryptography features are added

Confirm this against the final build before submission.

## 8. Content And Ratings

- Age Rating target: `4+`
- No gambling content
- No sexual content
- No medical claims
- No public chat or user-generated feed
- No unrestricted web browsing

## 9. Product Page Assets Checklist

- App icon `1024 x 1024`
- iPhone screenshots for required device sizes
- Optional app preview video
- Support page live
- Privacy policy page live

## 10. Submission Readiness Checklist

- Bundle ID created in Apple Developer
- App record created in App Store Connect
- Privacy Policy URL reachable
- Support URL reachable
- App Privacy questionnaire completed
- Age Rating questionnaire completed
- Pricing selected
- Countries selected
- Screenshots uploaded
- Build uploaded
- Review notes added
