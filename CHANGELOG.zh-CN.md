# 更新日志

[English](CHANGELOG.md) | **简体中文**

本项目所有重要改动都会记录在此。
格式参考 [Keep a Changelog](https://keepachangelog.com/)。

## [1.0] - 2026-10-16

### 新增
- 首个版本。
- 通过 `ro.config.*_vol_steps` 属性调整媒体/闹钟/系统/通话音量阶梯（本次开机生效）。
- 通过 root fabricate 的 RRO 叠加层调整铃声/通知阶梯（下次开机生效）。
- 单文件用户配置（`config.sh`）。
- 干净的卸载钩子，注销所创建的叠加层。
