# Changelog

**English** | [简体中文](CHANGELOG.zh-CN.md)

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0] - 2026-10-16

### Added
- Initial release.
- Tune Media / Alarm / System / Call volume steps via `ro.config.*_vol_steps`
  properties (applied on the same boot).
- Tune Ringtone / Notification steps via a root-fabricated Runtime Resource
  Overlay (applied from the next boot).
- Single-file user configuration (`config.sh`).
- Clean uninstall hook that unregisters the fabricated overlays.
