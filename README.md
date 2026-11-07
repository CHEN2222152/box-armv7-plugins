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

当前 armv7 转换结果：17 项 APK 已落到 `plugins/armv7/`，1 项继续使用原包内置 Python，
2 项仍待原生 SDK 重编：

- 已转换：AliYunPlayer、Cat Spider、drpyS、EXO、GoProxy、IJK、荐片、Legado、
  洛雪音源、MPV、Node、PHP、PHP Spider、Python Spider、QuickJS Spider、迅雷、
  YouTube
- 内置：Python 运行时使用原宝盒 Chaquopy 3.8
- 待重编：MDK Player、RedPlayer，清单标记 `needs-armv7-rebuild`

每个转换包都在 `plugins/armv7/SHA256SUMS.txt` 和 `CONVERTED.csv` 中记录哈希。
所有已生成 `lib/` 和 assets ELF 都经过检查，为 `ELF32 / ARM`。

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

## 转换流程

```powershell
.\scripts\convert-armv7-plugins.ps1
```

转换器以官方插件 APK 为母体，只移除 arm64/x86 目录并替换为 armv7 库或 assets；
纯 Java 插件直接复制。转换后运行：

```powershell
.\scripts\validate-market.ps1
```

## 发布流程

1. 在 GitHub 创建 `box-armv7-plugins` 仓库。
2. 推送本目录。
3. 大型 APK 可以放在 Releases；清单中的 `downloadUrl` 与 `sha256` 必须同步。
4. 修改 `plugins.json` 后运行 `scripts/validate-market.ps1`。

如需 GitHub Pages，需要仓库管理员先在 Settings -> Pages 中手动启用一次，再使用
`https://chen2222152.github.io/box-armv7-plugins/plugins.json`。

## 分发边界

`plugins/armv7/` 中的 APK 是基于用户提供的官方插件包做 ABI 替换和纯 Java 直接复用。
公开发布前必须确认拥有对应插件的再分发授权。MDK 和 RedPlayer 尚未生成 armv7 版本，
不会在清单中伪装成可用。
