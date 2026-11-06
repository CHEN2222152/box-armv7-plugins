# 宝盒 armv7 插件仓库

这是传统 TVBox / 宝盒 armv7 测试包的在线插件市场仓库，不包含官方
`tv.box.bh`、`tv.box.bh.mb` 或官方 64 位插件 APK。

## 入口

插件中心使用 GitHub raw 地址：

```text
https://raw.githubusercontent.com/CHEN2222152/box-armv7-plugins/main/plugins.json
```

把上述地址填入 TV 的“设置 -> 插件中心 -> 插件市场地址”，点击“加载市场”即可。

## 当前清单

清单包含官方手机版 3.8.7 的 20 个原配分类项，并明确记录 armv7 兼容状态：

- `builtin`: 已由 armv7 TV 包内置实现，可立即使用。
- `bundle`: 市场托管的 ZIP 配置插件，必须提供 `downloadUrl`。
- `official-apk`: 官方原包仅用于兼容性展示，不下载、不伪装为可执行。
- `official-apk-java`: 纯 Java 官方 APK，由宿主下载、校验并通过 DexClassLoader 加载。

当前内置可用项：

- AliYunPlayer
- EXO Player
- IJK Player
- Python Spider 插件
- Python 运行时
- QuickJS Spider 插件
- YouTube 播放插件（纯 Java APK 宿主）
- Legado 书源插件（纯 Java APK 服务宿主）

运行时与 Node.js Spider：

- Node.js 运行时为 Node.js Mobile 18.20.4 的 armv7 构建。
- Cat Spider、drpyS Spider、洛雪音源通过纯 Java APK 宿主加载，依赖 Node.js 运行时。
- PHP 运行时为基于 PHP 8.2.35 源码构建的 armv7 CLI，包含 curl/mbedTLS、DOM、mbstring 和 zlib。
- PHP Spider 通过纯 Java APK 宿主加载，依赖 PHP 运行时。

Python 项只在 Python 版 TV 包中可用；Java 版会显示需要 Python 版。其余带 arm64 native
依赖的官方插件仍保持“待 armv7 重编”。

## ZIP 插件发布

`bundle` 插件必须包含 `plugin.json`，否则安装后会报“插件缺少配置”。

建议把 ZIP 放在 GitHub Releases，并在清单中填写：

```json
{
  "id": "codex.armv7.example",
  "name": "示例插件",
  "type": "config",
  "versionName": "1.0.0",
  "description": "示例",
  "provider": "bundle",
  "abi": "any",
  "compatibility": "available",
  "downloadUrl": "https://github.com/<USER>/box-armv7-plugins/releases/download/v1.0.0/example.zip",
  "config": "plugin.json",
  "sha256": "<ZIP_SHA256>"
}
```

客户端会校验 `sha256`，不匹配时删除下载文件并拒绝安装。

下载器会依次尝试 `downloadUrl` 和 `downloadUrls`，保留未完成的 `.part` 文件并
使用 HTTP Range 续传；每个源失败后会自动重试，全部完成后才进行 SHA256 校验。

## 发布流程

1. 在 GitHub 创建 `box-armv7-plugins` 仓库。
2. 推送本目录。
3. 大文件不要直接提交到 Git，放到 Releases。
4. 修改 `plugins.json` 后运行 `scripts/validate-market.ps1`。

如需 GitHub Pages，需要仓库管理员先在 Settings -> Pages 中手动启用一次，再使用
`https://chen2222152.github.io/box-armv7-plugins/plugins.json`。

## 分发边界

官方插件包未提供源码和明确再分发许可，本仓库不上传其 APK 或反编译产物。
带 native 的插件只能发布基于有许可源码的 armv7 重编版本，并使用独立 ID。
