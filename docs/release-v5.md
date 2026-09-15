## v5 — 链路自诊断灯版（一个版号，两个 edition）

功能与 v3.3/v4 完全一致，**新增链路健康自诊断**：主半每秒 `0xF1` RPC 与从半互报状态，每半把**自己那侧 `7` 键**点成——

- **常绿**：数据链路正常
- **红闪**（400ms）：数据不通（坏线 / 从半亏电 / 线没插）— B 版任何模式；A 版仅有线（无线休眠期不闪，防误报）
- **黄闪**：有线下"一半有 5V、一半没有"= 数据线好、供电线坏
- F 模式期间让位给 13 键红灯排；RGB 关闭/效果 NONE 时所有指示不显示（QMK 指示钩子固有行为）

专治三种玄学线："只供电不传数据 / 只传数据不供电 / 全好"，插线 3 秒见分晓。

### 选哪个
| edition | 无线深睡 | 久置后唤醒 | 红灯语义 | SHA-256 (.bin) |
|---|---|---|---|---|
| **A**（续航优先） | 保留（数月待机） | 仅左半可唤醒 | 仅有线闪红 | `73379936d8531b2bd5d904828c8c2bfba458bdc62b6da070f80afdd0317e04ce` |
| **B**（体验优先，推荐） | 关闭（数周~月） | 双侧即按即醒 | 全程有效 | `2936e47a0446f29ca174eb45a6bbdd345f1542774d0021c7c569dafe5f9906d5` |

USB 有线模式下两版行为一致（均不深睡）。想换 edition 直接重刷对应 bin，键位不受影响。

### 复现构建
```bash
# 基线 SRGBmods/EpomakerQMK@10dfd3e8 + patches/split65-v5.patch
make epomaker/split65:default                      # -> A
make epomaker/split65:default LINK_WATCH_ALWAYS=yes # -> B
```
附件：`*-v5A.bin/.hex`、`*-v5B.bin/.hex`、`SHA256SUMS.txt`。刷写与救砖见 docs/flashing-guide.zh.md。
