## v5.5 — Windows Fn+F 排 = 功能键排

在 v5.4 全部功能上新增（Mac 路径未动）：

**触发**：`Fn+左Ctrl` 切到 F 排（数字排亮红灯）→ **按住 Fn + F1~F12 位置** → 功能键；**不按 Fn = 真 F1~F12**（现状不变）。

| Fn+Fx | 功能 | 键码 |
|---|---|---|
| F1 | 计算器 | `KC_CALC` |
| F2 | 屏幕亮度 − | `KC_BRID` |
| F3 | 屏幕亮度 + | `KC_BRIU` |
| F4 | 邮件 | `KC_MAIL` |
| F5 | 切到输入法①（搜狗） | `KC_F13` |
| F6 | 切到输入法②（英文） | `KC_F14` |
| F7 | 切到输入法③（Google日语） | `KC_F15` |
| F8 | 上一曲 | `KC_MPRV` |
| F9 | 播放/暂停 | `KC_MPLY` |
| F10 | 下一曲 | `KC_MNXT` |
| F11 | 任务管理器 | `Ctrl+Shift+Esc` |
| F12 | 睡眠 | `KC_SLEP` |

**F13/F14/F15 需要 PC 端配套**：AutoHotkey 脚本监听这三个键精确切换指定输入法（脚本与部署见 `IME_QUICK_SWITCH.md` / `ime-switch.ahk`）。不装 AHK 时这三个键无效果（F13~F15 为标准 HID，无系统副作用）。

其余（诊断灯、充电指示、休眠、PrtSc 右Shift、Esc↔` 互换等）与 v5.4 完全一致。

| | v5.5-A（深睡/续航） | v5.5-B（常醒，推荐） |
|---|---|---|
| .bin SHA-256 | `8e875d6bd1e31b821649b5eabb6d769f39e7ef9839cfad8b9f62deaf3da4caf0` | `380ee0e7eb55cb6bde4bc5a9956796ddd946e94f3fa4c5183f7e9cefb6e9620a` |
| 大小 | 75372 B | 75364 B |

复现：基线 `SRGBmods/EpomakerQMK@10dfd3e8` + `patches/split65-v5.5.patch`；A 版 `make epomaker/split65:default`，B 版加 `LINK_WATCH_ALWAYS=yes`。
刷写：两半各一次；bootmagic 清 EEPROM 后 VIA 重 Import。**认准 v5.5 文件名**。
