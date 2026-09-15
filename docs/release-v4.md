## v4 — 常醒版 / always-awake build（体验优先）= 推荐

与 v3.3 **功能完全一致**，唯一差异：`lpwr_is_allow_timeout_hook() => false`，两半**永不进 LPWR 深睡**：

- ✅ 左右任意键第一下即响应（含无线久置后）≈ 出厂行为
- ✅ 彻底规避从半深睡引发的一系列唤醒边角问题
- ⚠️ 代价：无线待机从"数月"降为"数周~月"（RGB 2 分钟超时熄灯、BT 30 分钟断开等浅睡机制仍保留）

**产物** `firmware/v4/`：`.bin` 74436 B，SHA256 见 `SHA256SUMS.txt`（`e8118285…154cfa5f`）。
**可复现**：基线 `SRGBmods/EpomakerQMK@10dfd3e8` + `patches/split65-v4.patch` → `make epomaker/split65:default`（本仓 tag `v4`；已验证重建字节一致）。
**刷写**：同 v3.3（两半各一次；详见 docs/flashing-guide.zh.md）。
