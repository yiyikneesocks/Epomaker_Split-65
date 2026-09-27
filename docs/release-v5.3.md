## v5.3 — PrtSc 触发收窄（右 Shift 专用）

与 v5.2 的唯一差异：**右 Shift + Backspace = PrtSc**；**左 Shift + Backspace = 普通退格**（左右同按视为右 Shift 触发）。

- 实现方式：修饰位判定从 `MOD_MASK_SHIFT` 收窄为 `MOD_BIT(KC_RSFT)`；发键瞬间仍自动摘除右 Shift（规避 Windows `Shift+PrtSc` 空绑定），释放后精确恢复
- 诊断灯（红/灭/恢复绿闪）、提示灯亮度（灯效+1 档封顶）等 v5.2 语义全部不变

| | v5.3-A（深睡/续航） | v5.3-B（常醒，推荐） |
|---|---|---|
| 无线深睡 | 保留（数月待机）；久置后按左半唤醒整键 | 关闭（数周~月）；任意键即醒 |
| .bin SHA-256 | `4902bec44a8a1c6fbef6fe2381b3bab80d09212f98a459eff2d45f160b5ac13b` | `2aa90620fdc29e323026699810ab1b11af7de4beefb8aa911cec4727ff1e3247` |
| 大小 | 74760 B | 74752 B |

复现：基线 `SRGBmods/EpomakerQMK@10dfd3e8` + `patches/split65-v5.3.patch`；`make epomaker/split65:default`（A）/ 加 `LINK_WATCH_ALWAYS=yes`（B）。
刷写：两半各一次；bootmagic 进 DFU 会清 VIA 键位。**文件名认准 v5.3**。
