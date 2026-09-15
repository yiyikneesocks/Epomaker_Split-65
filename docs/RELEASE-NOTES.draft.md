# Release 草稿（推上去后对应 `gh release create` 的正文）

## v3.3（Tag: v3.3）
**EPOMAKER Split65 自定义固件 v3.3 — 保留深睡（续航优先）**

功能：
- Esc ↔ ` 双向互换：F 模式(Fn+Ctrl, KC_FILP)开启且未按 Fn 时互换；数字行↔F1~F12 厂商逻辑保留
- F 模式指示：ESC+数字+- = 共 13 键亮红（亮度=主灯效+2档，封顶）
- CapsLock / Win 锁指示改红
- 亮度到顶/到底 ↑/↓ 白闪提示；修复最暗右半灯效冻结
- Shift+Backspace = PrtSc（自动摘 Shift，干净边沿）
- USB 模式两半均不深睡（修久置右半失灵）；无线保留 LPWR 深睡 → **久置后只能按左半唤醒**（协议限制，见 docs/pitfalls.zh.md）
- 内置默认键位：基础层顶左 = `，Fn 层顶左 = Esc

附件：epomaker_split65_default.bin/.hex（v3.3 目录，SHA256=7764dabf…/34d0bb37… 见 SHA256SUMS.txt）
刷写：左右两半各一次；QMK Toolbox + Zadig(WinUSB)；bootmagic 进 DFU 会清 VIA 键位。

## v4（Tag: v4）
**EPOMAKER Split65 自定义固件 v4 — 关闭深睡（体验优先）= v3.3 全部功能 + 双侧即按即醒**

与 v3.3 唯一差异：`lpwr_is_allow_timeout_hook()` 恒 false，无线不再进 LPWR 深睡：
- 左/右任意键第一下即响应（≈出厂行为）
- 代价：无线待机从"数月"降为"数周~月"（RGB 2 分钟熄灯、BT 30 分钟断开等浅睡保留）

附件：epomaker_split65_default.bin/.hex（v4 目录，SHA256=e8118285…/见 SHA256SUMS.txt）
其余同 v3.3。
