# Rental Report — Google Play 上架包

**状态：英文文案、图标及横幅已准备；手机图为版式草稿，等待 Android 英文实拍替换。**

## 本产品的发布前事项

- 重要：AppModel.empty() 每次启动创建空模型；未实现跨重启记录保存。上架前补持久化并验证重启及升级。
- 没有入住与退租自动对照实现，不宣传自动损坏对比。
- 当前代码中的 PDF 包含照片、说明和签名；仍需在 Android 验证拍照、签名、导出和分享。

## 在另一台电脑使用

运行 `git pull` 后打开 `google-play/`。

- `listing/en-US/title.txt`、`short-description.txt`、`full-description.txt`：复制到商店文案字段。
- `graphics/icon-512.png`：商店图标。
- `graphics/feature-graphic-1024x500.png`：特色横幅。
- `preview.html`：本地打开查看素材和文案。
- `screenshots-draft/`：版式草稿，不作为 Android 实拍成品上传。
- `source/ios-reference/`：已有真实 iOS 截图，供画面和场景参考；没有伪造英文界面。
- `capture-plan.json`：Android 最终实拍场景、文件名和文案。
- `store-setup.md`、`data-safety-review.md`、`release-checklist.md`：Play Console 填写参考。
- `privacy-policy-draft.html`、`support-draft.html`：针对 Android 的英文页面草稿，尚未发布到公共网站。

## 最终截图替换

1. 在 Android 版完成英文界面并验证核心功能。
2. 在模拟器或真机上打开 `capture-plan.json` 中的每个场景，存为 `source/android/<文件名>.png`。每张至少 1080 px 宽；不要包含通知、个人资料或测试浮层。
3. 在 `source/android/capture-provenance.json` 记录来源：`{"platform":"android","locale":"en-US","build":"你的 versionName/versionCode","device":"设备或模拟器型号"}`。
4. 在 `google-play/tools` 安装工具依赖：`npm install`；执行 `npx playwright install chromium`。
5. 回到项目根目录运行 `node google-play/tools/render.mjs --final`。
6. 检查 `screenshots-final/` 成品，上传与正式 Android 构建一致的截图。

`--final` 只读取 Android 目录，并要求 Android/en-US 来源记录；不会把 iOS 参考图自动当作 Android 实拍。脚本会使用短标题加实际界面、无手机外框的 1080×1920 排版。

## 素材规格

- 手机图：1080×1920，24 位 RGB PNG，六张。
- 横幅：1024×500，24 位 RGB PNG。
- 图标：512×512，32 位 RGBA PNG，小于 1 MB。
- 主色沿用应用：工具应用采用简洁的技术排版，Rental Report 采用明亮的房屋记录风格。
- 英文文案按现有源码撰写；未来增减功能、SDK或收费方案后必须重新核对。

## 来源

- [Google Play 预览素材要求](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en)
- [商店字段要求](https://support.google.com/googleplay/android-developer/answer/113469?hl=en)
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)

本包准备素材，不执行 Google Play 提交，不发布公共隐私页，不修改应用逻辑。
