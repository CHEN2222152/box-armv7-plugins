# armv7 插件 APK

本目录由 `scripts/convert-armv7-plugins.ps1` 生成。

- 17 个 APK 已转换为 armv7 或为纯 Java。
- 原生库和 assets 中的 ELF 均应为 `ELF32 / ARM`。
- `SHA256SUMS.txt` 是清单引用的设备端校验值。
- `CONVERTED.csv` 同时记录文件、大小、SHA256 和 raw URL。
- MDK Player、RedPlayer 需要上游原生 SDK 源码或 armv7 预编译库，当前未生成。
