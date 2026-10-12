# Rental-Report：另一台电脑接手 Google Play

## 仓库与当前状态

- 私有仓库：https://github.com/workyan/Rental-Report
- 本次同步现有 Flutter 源码、资源、依赖锁定文件、测试和产品文档。
- 当前项目只有 iOS 平台目录，尚未生成 Android 工程，也未验证 Android 构建。
- 现有 iOS Bundle ID：`com.cc.rentalreport`。Android applicationId 需要在首次提交 Google Play 前确认。
- 本机 Flutter：3.44.8 stable，Dart 3.12.2；pubspec 要求 Dart ^3.11.5。此版本记录不代表已验证 Android。
- 当前产品已有英文定位；Android 上需要验证拍照、文件保存、签名及 PDF 导出和分享。

## 在另一台电脑拉取

先安装 Flutter、Android SDK，并使用有权访问 workyan 私有仓库的 GitHub 账号登录。

```bash
gh auth login
gh repo clone workyan/Rental-Report
cd Rental-Report
flutter doctor
flutter create --platforms=android .
flutter pub get
flutter analyze
flutter test
flutter run
```

生成 Android 工程后，查看 Git 差异，并确认应用名称、图标、applicationId、插件要求、权限和目标 Android SDK。生成目录是迁移起点，不代表已完成适配。

## 发布前的工作

1. 完成海外本地化，并在 Android 真机上验证核心功能、数据保存和分享。
2. 确定 Google Play 商业模式；如采用应用内付费，需要接入并验证 Google Play Billing，现有 iOS 买断定价文档不会自动配置 Android 收费。
3. 按 Flutter 的 Android 发布流程创建上传密钥，在本机配置 release 签名；密钥和密码不提交 GitHub，另行备份。
4. 在签名及构建配置完成后运行 `flutter build appbundle --release`，产物位于 `build/app/outputs/bundle/release/`。
5. 准备英文商店文案、Android 截图、隐私政策和 Data safety 信息，并按开发者账号要求进行测试和审核。

已有 App Store 截图和文档可供参考，需检查并替换其中的 iPhone、App Store 和中国区定价内容。


## 已准备的 Google Play 信息与素材

参阅 [google-play/README.md](google-play/README.md)。图标和横幅可用于商店；截图草稿仍需替换为 Android 正式构建的英文实拍。发布前注意 README 中列出的代码缺口。
