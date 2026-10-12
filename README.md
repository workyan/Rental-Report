# Rental-Report

Paid iPhone app for rental move-in and move-out inspection reports.

## Product Decision

- App name: `Rental-Report`
- Storefront: `iPhone`, `English (U.S.)` first
- Pricing: `US$4.99` one-time paid download
- Acquisition: `App Store search` first
- Positioning: `simple room-by-room inspection report app for landlords, tenants, and Airbnb hosts`

## Included Docs

- [PRD.md](/Users/cc/StudioProjects/Rental-Report/PRD.md)
- [ASO.md](/Users/cc/StudioProjects/Rental-Report/ASO.md)
- [APP_STORE_CONNECT.md](/Users/cc/StudioProjects/Rental-Report/APP_STORE_CONNECT.md)
- [SOURCES.md](/Users/cc/StudioProjects/Rental-Report/SOURCES.md)

## Naming Rationale

`Rental-Report` is intentionally search-first rather than brand-first:

- `Rental` matches the highest-intent market term.
- `Report` matches how users think about evidence, PDFs, and deposit disputes.
- The hyphen keeps the required `xxx-xxx` format.
- The title stays short enough to leave room for a highly searchable subtitle.

This is not a trademark clearance result. It is a practical ASO naming choice.

## Google Play / Android

Android 项目已加入，applicationId 为 `com.cc.rentalreport`。英文 Google Play 素材包含六张真实 Android 截图、图标、横幅和商店文案。

- [上架素材与预览](google-play/README.md)
- [另一台电脑的构建、测试和本地签名步骤](google-play/android-release.md)
- [提交前检查](google-play/release-checklist.md)

```bash
flutter pub get
flutter build apk --debug --target-platform android-arm64
```

房屋、检查、照片路径、问题记录和输入姓名确认现已保存在设备私有目录，退出重开可恢复。
