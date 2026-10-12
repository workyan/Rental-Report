# Rental Report — Google Play 上架包

英文商店素材已从真实 Android 界面导出。上传使用 `screenshots-final/`，每款六张；`screenshots-draft/` 和 iOS 参考图仅保留作历史参考。

## 在另一台电脑使用

`git pull` 后打开 `google-play/preview.html` 查看整套素材与英文文案。

| Play Console 字段 | 文件 |
|---|---|
| 名称 / 简短描述 / 完整描述 | `listing/en-US/` 三个对应 txt |
| 新版本说明 | `listing/en-US/release-notes.txt` |
| 高分辨率图标 | `graphics/icon-512.png`：512×512 RGBA PNG |
| 特色横幅 | `graphics/feature-graphic-1024x500.png`：1024×500 RGB PNG |
| 手机截图，按编号排序 | `screenshots-final/`：六张 1080×1920 RGB PNG |
| 素材总览 | `contact-sheet-final.png` |
| 填写说明 | `store-setup.md`、`data-safety-review.md` |
| 发布前事项 | `release-checklist.md`、`android-release.md` |

视觉方向：房屋记录编辑风格：海军蓝、浅底、衬线标题与真实照片。每张只讲一个用途，英文标题与实际界面分开排版，没有价格、排名、下载量或虚构功能。

## 真实截图如何生成

1. 编译当前 Flutter App 的 Android 英文 debug APK。
2. 在 API 35 ARM64 模拟器以 1080×1920、density 320 运行真实页面。
3. debug 专用场景入口填入演示数据，等待布局稳定；需要时滚动真实页面。
4. 用 `adb exec-out screencap -p` 采集原始 PNG，保存到 `source/android/`。
5. 截图工厂以 HTML 排版标题和真实界面，由 Playwright、html-to-image 导出；只裁掉系统状态栏和导航栏。
6. 检查画面、文字、内容与代码一致性，验证尺寸、RGB/RGBA、非空白和文案字符数。

演示入口由 Android debug 标记保护，正式 release 不接受截图 intent。原始截图未重绘 App 控件。`capture-provenance.json` 记录 APK SHA-256、设备、时间、场景和原图 SHA-256；截图来自 debug 构建，上传前仍须核对签名 release 的显示与功能。

## 可重复生成

项目根目录执行（Flutter 3.44.8 / Dart 3.12.2 已验证，JDK 17+）：

```bash
flutter pub get
flutter build apk --debug --target-platform android-arm64
python3 google-play/tools/capture-android.py .
```

先启动 Android 设备或模拟器，确保 `adb` 在 PATH，设备分辨率为 1080×1920。三款采集共用设备时必须逐款运行。

```bash
cd google-play/tools
npm ci
npx playwright install chromium
cd ../..
node google-play/tools/render.mjs --final
```

生成器以 `/Users/cc/StudioProjects/app-store-shot-factory/scripts/` 为统一来源；交付包包含脚本副本和固定版本依赖，在另一台电脑不需要这个绝对路径。最终模式只接受真实 Android/en-US 来源记录。

## 功能边界和发布事项

- 参与者确认使用输入的姓名和时间，没有手写签名轨迹。
- 没有入住与退租自动对比功能。

素材已完成；本包没有代替你配置 Play 账号、生产上传密钥或提交审核。Android 英文隐私/支持页的本地版本在 `privacy-policy-draft.html` 和 `support-draft.html`，尚未发布到公共网站。已有网站目前为 iOS 内容，需要更新后再用于 Android 提交。

核对结果见 `verification-report.json`、`source-audit.json`、`quality-review.json`。可在项目根目录运行 `python3 google-play/tools/verify-package.py .` 校验来源、原图及成品哈希、PNG 格式和文案限制。可在项目根目录运行 `python3 google-play/tools/verify-package.py .` 校验来源、原图及成品哈希、PNG 格式和文案限制。

[Google Play 素材要求](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en) · [商店字段要求](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)
