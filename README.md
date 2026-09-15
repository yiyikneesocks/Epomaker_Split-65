# EPOMAKER Split65 — Custom QMK Firmware (Esc/` swap, PrtSc, indicator fixes)

> **Unofficial community firmware.** Not affiliated with EPOMAKER. Hardware: EPOMAKER Split65 (WB32FQ95, hs/MMS tri-mode wireless, split). License: GPL-2.0-or-later (derived from QMK).
> 非官方社区固件，仅适用于 WB32 主控的 EPOMAKER Split65（三模分体）。风险自负，变砖自救方法见文档（ROM 内 DFU，正常刷写几乎不会真砖）。

**TL;DR / 快速上手**

📦 **Releases（直接下现成固件）**：
- [**v5.1**（推荐）](https://github.com/yiyikneesocks/Epomaker_Split-65/releases/tag/v5.1)：链路诊断状态机版，含 A/B 两 edition
- [v5](https://github.com/yiyikneesocks/Epomaker_Split-65/releases/tag/v5)：初版诊断灯（6/7 键，已被 v5.1 取代）
- [v4 常醒版](https://github.com/yiyikneesocks/Epomaker_Split-65/releases/tag/v4) ｜ [v3.3 深睡版](https://github.com/yiyikneesocks/Epomaker_Split-65/releases/tag/v3.3)（=v5 去掉链路自诊断灯）

1. 下载 Release 里对应版本的 `.bin`（校验同附 `SHA256SUMS.txt`）。
2. **左右两半各刷一次**（同一文件）：左半按住 `ESC` 插 USB 进 DFU；右半先拨 RShift 后方开关到"下"、拔空格键帽+轴、用镊子**短接空格位两个触点**的同时插 USB（见 `docs/flashing-guide.zh.md` §5.3，示意图：<https://assets.st-note.com/img/1766185706-KeYQVmIEbskUu87qSOpFwDRy.jpg>）。刷过本固件后右半改为"按住 `7` 插线"。
3. Windows 用 **QMK Toolbox**（含 wb32-dfu-updater）；首次需在 **Zadig** 里给 `WB Device in DFU Mode (342D:DFA0)` 绑定 **WinUSB** 驱动，否则 `wb32-dfu-updater_cli` 报 `No DFU capable USB device available`（Toolbox 依旧会误报 "Flash complete"，以日志为准）。
4. 用 DFU(bootmagic) 方式进刷写模式**会清空 VIA 键位**，回落到固件内置默认层（本仓库 default keymap 已按下面"默认行为"摆好）。有自定义键位的先用 VIA 导出，刷完导入。

## v5.1 的两个版本怎么选（当前推荐；一个版号、两个 edition）

| | **v5.1-A** 深睡版 | **v5.1-B** 常醒版 ✅推荐 |
|---|---|---|
| 功能（全相同，含链路诊断状态机） | 见下"功能"与指南附录 E | 同左 |
| LPWR 深睡（无线） | **保留**：待机"数月" | **关闭**：待机"数周~月" |
| 无线久置后唤醒 | **只能按左半**唤醒整键（右半灯效由主半单链驱动，照常亮；按右半叫不醒主半） | 左右任意键即按即醒 |
| 链路诊断灯 | 全模式生效（右半常年在线，无误报基础） | 同左 |
| USB 有线模式 | 两半都不深睡，正常 | 同左 |
| SHA-256 (.bin) | `c6ce1034…38a33e30` | `ee31d8d7…a6fd7056` |

> 两版**同一份源码**，只差构建开关：`make epomaker/split65:default [LINK_WATCH_ALWAYS=yes]`。v5 各版（无状态机、灯在 6/7、+2 档）已被 v5.1 取代，releases 仍可下载。
> 两版**同一份源码**，只差一个构建开关：`make epomaker/split65:default [LINK_WATCH_ALWAYS=yes]`。想换版本只需重刷，键位/EEPROM 不动。旧 release v3.3/v4 保留可下。

## 功能（两版一致）

- **`Esc` ↔ `` ` `` 按模式互换**：所有层通用、按 keycode 生效（VIA 里格子显示什么平时就按出什么）。按 `Fn+Ctrl`（原 `CUSTOM(21)`/`KC_FILP`，硬编码在固件里）进入 "F 模式"（数字行↔F1~F12 的厂商逻辑保留）后：`Esc` 格 ↔ grave 格 互换输出，即顶左变**真 Esc**，`Shift+Ctrl+Esc` 等组合键恢复可用；按住 Fn（`_FL`/`_MFL`）期间不参与互换。
- **F 模式指示灯**：`ESC` + 数字 + `-` `=` 共 13 键亮红（替代厂商"0 键白灯"）。
- **CapsLock / Win 锁（Fn+Win）指示改红色**。
- **亮度极限提示**：调至最亮/最暗时 `↑`/`↓` 键白闪两下；并修复"调最暗右半灯效卡死不动"（原版拉 LED 电源轨的竞态）。
- **亮度联动**：以上指示亮度 = 主灯效亮度 **+2 档**、封顶最亮（最暗时指示仍可见，夜晚不刺眼）。
- **Shift+Backspace = PrintScreen**（先按住 Shift 再按退格触发；发键瞬间自动摘除 Shift，避免 Windows 的 `Shift+PrtSc` 空绑定；普通退格/按住退格连删不受影响）。
- 内置 default keymap：基础层顶左 = `` ` ``，Fn 层顶左 = `Esc`（bootmagic 清 EEPROM 后直接是你的常用布局）。
- **v5.1 链路诊断状态机（左右 Ctrl 键）**：正常=**灭**；进异常（断线/数据坏=**红**、有线供电断=**黄**）**先闪 3 下→常亮**；恢复=**绿闪 3 下→灭**；开机即异常=直接常亮。单链模型下右半灯效照常由主半点亮，详见附录 E。
- 修复厂商 fork 的若干回归：USB 模式从半深睡导致的"久置右半失灵需重插连接线"等（详见 `docs/pitfalls.zh.md`）。

## 文件

```
firmware/v5.1/   # 当前推荐（A/B 的 .bin/.hex + SHA256SUMS）
firmware/v5/     # 历史版本
firmware/v3.3/, firmware/v4/   # 历史版本（.bin/.hex + SHA256SUMS.txt）
patches/                       # 相对 SRGBmods/EpomakerQMK@10dfd3e8 的键盘目录 diff（可审计/自建）
via/EPOMAKER Split65.json      # 官方 VIA 布局描述文件（改键用）
docs/flashing-guide.zh.md      # 详细刷写+备份+防变砖+救砖指南（中文）
docs/pitfalls.zh.md            # 踩坑记录/技术考古（中文，为何"只左半能醒"等）
build.sh                       # 一键：clone 基线 + 打补丁 + 编译
```

## 自行构建 / 复现

- 基线：`SRGBmods/EpomakerQMK` @ `10dfd3e8`（自带 WB32 平台 + Split65 + 内嵌 wireless 模块；README 标注 Split65 Tested）。
- 本仓库各 tag 对应的源码提交可**字节级复现**发布产物（构建嵌入的 git hash 不进入 `.bin`，已验证 SHA 一致）。v5 两版=同一 commit 不同构建参数。
- 环境：`gcc-arm-none-eabi`、`python3 -m venv` + `pip install -r requirements.txt qmk`、`qmk config user.qmk_home=<树>`；构建：A 版 `make epomaker/split65:default`，B 版加 `LINK_WATCH_ALWAYS=yes`。或 `./build.sh v5 [a|b]`（脚本已支持）。
- 已知注意：上游 readme 里的 `-km via` 键位在本树不存在，用 `default`；子模块 `lib/chibios*` 首次 `make` 会自动拉取。

## Credits / 致谢

- 硬件与源码：[Epomaker/Split65](https://github.com/Epomaker/Split65)（官方键盘目录）
- 可编译环境：[SRGBmods/EpomakerQMK](https://github.com/SRGBmods/EpomakerQMK)（基于 [carlosedp/qmk_firmware](https://github.com/carlosedp/qmk_firmware) WB32 分支）、[hangshengkeji/qmk_firmware](https://github.com/hangshengkeji/qmk_firmware) `tri-mode`（同源基线，路径有出入）
- 刷写工具：[WestberryTech/wb32-dfu-updater](https://github.com/WestberryTech/wb32-dfu-updater) · [QMK Toolbox](https://qmk.fm/toolbox) · [Zadig](https://zadig.akeo.ie/)
- 右半短接示意图：st-note 社区图（链接见上）
