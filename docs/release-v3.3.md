## v3.3 — 深睡版 / deep-sleep build（续航优先）

**功能（两版一致）**
- `Esc` ↔ `` ` `` 按 keycode 双向互换：F 模式（Fn+Ctrl = `KC_FILP`）开启且未按 Fn 时互换；平时 VIA 所见即所得。数字行↔F1~F12 厂商逻辑保留。
- `Shift+Backspace` = PrintScreen（发键瞬间自动摘除 Shift，Windows 截图必达；先按 Shift 再按退格触发）。
- F 模式指示：`ESC`+数字+`-`+`=` 共 13 键**红灯**；CapsLock/Win 锁**红灯**；亮度到顶/到底 `↑`/`↓` **白闪**。指示亮度 = 主灯效 +2 档（封顶最亮，最暗时仍可见）。
- 修复：最暗右半灯效冻结；USB 模式从半深睡导致"右半久置失灵"。
- 内置默认键位：基础层顶左 = `` ` ``，Fn 层顶左 = `Esc`（bootmagic 清 EEPROM 后直接可用）。

**本版本取舍**：保留 SRGBmods 的无线 LPWR 深睡 → 待机"数月"；⚠️ 久置后**只有左半能唤醒**（协议方向限制，见 docs/pitfalls.zh.md §6；介意请选 v4）。

**产物** `firmware/v3.3/`：`.bin` 74444 B，SHA256 见 `SHA256SUMS.txt`（`7764dabf…ad4918e6`）。
**可复现**：基线 `SRGBmods/EpomakerQMK@10dfd3e8` + `patches/split65-v3.3.patch` → `make epomaker/split65:default`（本仓 tag `v3.3`；已验证重建字节一致）。
**刷写**：左右两半各一次（左：按住 ESC 插线；右：开关拨下+短接空格位，或已有本固件时按住 7）；Windows 首次需 Zadig 绑 WinUSB。详见 docs/flashing-guide.zh.md。
