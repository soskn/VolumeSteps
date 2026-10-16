# Changelog / 更新日志

All notable changes to this project are documented here.
本项目所有重要改动都会记录在此。

The format is based on [Keep a Changelog](https://keepachangelog.com/).
格式参考 [Keep a Changelog](https://keepachangelog.com/)。

## [1.0] - 2026-10-16

### Added / 新增
- Initial release. / 首个版本。
- Tune Media / Alarm / System / Call volume steps via `ro.config.*_vol_steps`
  properties (applied on the same boot). / 通过 `ro.config.*_vol_steps` 属性调整媒体/闹钟/系统/通话音量阶梯（本次开机生效）。
- Tune Ringtone / Notification steps via a root-fabricated Runtime Resource
  Overlay (applied from the next boot). / 通过 root fabricate 的 RRO 叠加层调整铃声/通知阶梯（下次开机生效）。
- Single-file user configuration (`config.sh`). / 单文件用户配置（`config.sh`）。
- Clean uninstall hook that unregisters the fabricated overlays. / 干净的卸载钩子，注销所创建的叠加层。
