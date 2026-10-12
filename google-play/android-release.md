# 在另一台电脑生成 Google Play 发行包

Android applicationId：`com.cc.rentalreport`。英文构建参数：`不需要，应用界面本身为英文`。

仓库已包含 Android 项目、真实英文界面、launcher 图标和上传签名配置入口。已验证 debug APK，正式发行密钥由你本地保存。

## 构建和测试

使用 Flutter 3.44.8 / Dart 3.12.2 或兼容版本，安装 Android SDK 和 JDK 17+。

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
```

## 上传密钥

首次发行可在安全的本地目录运行下面命令；密钥密码由终端提示输入：

```bash
keytool -genkeypair -v -keystore /your/private/path/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

将 `android/key.properties.example` 复制为 `android/key.properties`，在本机填写真实密钥路径、alias 和密码。密钥、密码配置和 `local.properties` 都由 gitignore 排除。密钥另做安全备份，已有上传密钥时沿用原密钥。

```bash
flutter build appbundle --release
```

输出：`build/app/outputs/bundle/release/app-release.aab`。未配置 `key.properties` 时 release 任务会明确失败，避免误用 debug 签名上传。当前 `versionName=1.0.0`、`versionCode=1`；每次更新提高 build number。

## 上传前

在内部测试轨道安装 Play 分发的签名版本，确认英文页面、返回操作、实际保存和分享与截图一致。Rental Report 另验证相机/系统照片选择、重启记录恢复、照片保存及 PDF。按照 Console 当前要求完成 target SDK、Data safety、应用访问、分级及账号适用测试流程；素材不等于审核通过。
