# EPOMAKER Split65 固件改造 · 全程踩坑记录

> 配套文档：`docs/flashing-guide.zh.md`（同目录）
> 当前发布：**v5.1（A/B 两版，链路诊断状态机 + 提示灯 +1 档）**；v5/v4/v3.3 保留。核心功能于 v3.3 全量实测通过；v5.1 实测中。

---

## 0. 右半短接图（外部图源，重要！）

repo 里 readme 引用的 `howto.jpg` 是**死链**（GitHub API 核实过：carlosedp / SRGBmods 仓库根本未提交该文件）。实际有效的右半短接示意图用的是社区转载图，**务必存档**：

> **右半 DFU 短接示意图（空格位焊盘）：**
> <https://assets.st-note.com/img/1766185706-KeYQVmIEbskUu87qSOpFwDRy.jpg?width=1200>

（2026-09-15 实测：按此图短接成功刷入右半。另注意右半 RShift 后方的物理开关：刷时拨下、**刷完必须拨回上**。）

---

## 1. 功能总账（v1→v3.3 都改了什么）

| 版本 | 内容 |
|---|---|
| v1 | FILP 开时 `ESC→\`/~`（极性做反，见 §5.1） |
| v2 | ①F 模式 13 键红灯排（LED22~34，替代原“0”键白灯）②Caps/Win 锁指示改红 ③亮度极限 ↑/↓ 白闪 ④**修右半最暗冻结**（删 VAD 拉电源轨逻辑）⑤**修右半久置失灵**（`lpwr_is_allow_timeout_hook` 恢复官方：USB 模式永不深睡）⑥FILP 状态 0xF0 RPC 同步从半 |
| v3 | ESC↔`` ` `` **双向互换**（FILP 开且未按 Fn 层时；按 keycode 匹配，全层通用）+ Shift+Backspace→PrtSc |
| v3.1 | 固件内置 default 键位改成 _BL/_MBL=`` ` ``、_FL/_MFL=Esc（移除 QK_GESC 误会源）；PrtSc 改 register/unregister 配对 |
| v3.2 | PrtSc **摘 Shift 干净边沿**（`get_mods` 存实际位→`del_mods`→`register_code16`→**`send_keyboard_report()`**→`add_mods` 精确装回） |
| v3.3 | 指示亮度联动：`hs_ind_val() = min(val + 2×STEP, MAX)`（当前 = +60 / 封顶 150），覆盖红灯排/白闪/Caps/Win |
| **v4** | **彻底禁用 LPWR 深睡**（`lpwr_is_allow_timeout_hook`→`return false`）：左右两半任意键即按即醒，恢复出厂唤醒行为；无线待机"数月→数周~月" |
| **v5** | 链路健康自诊断：`0xF1` RPC（每秒、互报充电态）+ 两侧 `7` 键灯（绿=数据好/红闪=数据断/黄闪=有线一半没5V）；A/B 同源码两版（`LINK_WATCH_ALWAYS=yes`） |
| **v5.1** | 实测修正架构（单链、主半画全灯、右半纯靠链路 5V）后：诊断灯挪至左右 Ctrl、撤销绿灯改**状态机**（闪3下→常亮、恢复绿闪3下、开机即坏直接常亮）、黄闪仅主半判、全部提示灯亮度 +1 档封顶 |

---

## 2. 选型与环境阶段的坑

1. **GitHub 直连 TLS 全部失败**（gnutls handshake / unexpected EOF）→ 全程 `https://gh-proxy.com/` 前缀克隆与 raw 抓取。该代理会**间歇 403**（bot 墙），且 **jsDelivr 也被网关拦**（`403 禁止访问` 页面）；`api.github.com` 反而可直连——排雷时优先用 API 列目录（本轮就是靠 API 证实 `howto.jpg` 不存在）。
2. **后台/`setsid` 分离的克隆会被杀**：工具超时后整个进程树被 SIGTERM（exit 143）。大克隆必须**前台阻塞 + 显式大 timeout**，一次一个。
3. **三个候选固件仓库的真伪核实**：
   - `EPOMAKER/qmk_firmware`（官方 fork）：有 WB32 平台，**没有 Split65、没有 linker/wireless 模块** → 编不了。
   - `hangshengkeji/qmk_firmware@tri-mode`：全都有，且 `.c` 与官方源码同构；**但**其 `post_rules.mk` 里 `include keyboards/leo/...` 与实际存放路径 `keyboards/epomaker/...` 自相矛盾（路径 bug 味），放置讲究。
   - **`SRGBmods/EpomakerQMK`：最终选择**。`epomaker/split65` 自带**键盘内嵌** `linker/wireless/`，`post_rules.mk` 用 `$(KEYBOARD)` 通用路径，README 明确 "Epomaker Split65 — Tested"。自足、无路径歧义。
   - 教训：**别信 readme 的编译命令**——它写着 `qmk compile -km via`，仓库里根本没有 `via` 键位，只有 `default`；还写着 `git clone carlosedp/...`。以目录实测为准。
4. **该 fork 没有 `bin/qmk` 启动脚本**：`pip install qmk`（qmk_cli 1.2.0）+ `qmk config user.qmk_home=<树目录>` 后 `make` 才认 CLI。venv 里 `import qmk` 直接失败属正常（`lib/python/qmk` 由固件树提供）。
5. **Python 环境按本机规范**（`~/CodingProgram/PYTHON_ENVIRONMENT.md`）：venv 隔离、走清华 pip 镜像、不 sudo pip。
6. **子模块**：`lib/chibios`、`lib/chibios-contrib`（WB32 HAL 在 contrib）；用仓库级 `git config url."https://gh-proxy.com/https://github.com/".insteadOf https://github.com/` 让 submodule 走代理。实际上 `make` 的引导会自动 `submodule update --init` **全部**子模块（googletest/lufa 等也一并拉了）。
7. **编译器**：Ubuntu 22.04 `gcc-arm-none-eabi 10.3` + `libnewlib-arm-none-eabi` 可用。
8. **WB32 刷写工具不是 dfu-util！**：`platforms/chibios/flash.mk` 明确走 `wb32-dfu-updater_cli -t -s 0x08000000 -D <bin>`；dfu-util 装了也用不上。QMK Toolbox 0.3.4 已内置支持。

## 3. 刷写阶段的坑（Windows 侧）

9. **`NO DRIVER ... should be WinUSB`**：WB32 ROM DFU 设备（`342D:DFA0`）Windows 不自动绑 WinUSB，libusb 打不开。**解法：Zadig 手动装 WinUSB**（Options→List All Devices→选 `WB Device in DFU Mode`→WinUSB→Install Driver）。
10. **`Flash complete` 是骗人的**：Toolbox 在 `No DFU capable USB device available`（即上面没驱动）时**照样打印 Flash complete**。判成败看有没有真实 erase/program 进度日志，不只看结束语。
11. **WSL↔Windows 文件**：Toolbox 在 Windows，产物在 WSL——要 `cp` 到 `/mnt/c/Users/...` 才选得到。
12. **bootmagic 进 DFU 会清 EEPROM**（代码 `bootmagic.c`：`bootmagic_should_reset()`→`eeconfig_disable()`→`bootloader_jump()`）：**每次**按 ESC/7 刷完键位都回固件内置默认层 → 要么重 Import VIA，要么像我们一样**把想要的布局烧进 default keymap**（v3.1 干了这事）。
13. **左右两半都要刷**，同一个 `.bin`；漏刷一半 = 行为诡异。
14. **拓扑真相**：**左半 = master**（双 USB-C：一个电脑、一个链路到右半），**右半单插无反应**（从半，固件层面无解）。

## 4. 验证方法论（不靠肉眼玄学）

- `sha256sum` 锁定产物；`git diff --numstat` 锁定改动面（曾借此确认只动了 1 个文件）。
- `strings *.elf` 找 `Split65-1/2/3`、`process_record_user_split65`；`.bin` 里搜 `2d34`/`c6e4`（VID/PID）确认是这块板的目标。
- **反汇编指纹**：`arm-none-eabi-objdump -d` + 数关键立即数出现次数——例如 `#53(0x35 KC_GRV)` 在未改源码里 **0 次**、在产物里 **恰好 1 次**；`del_mods→#70→send_keyboard_report→add_mods` 序列存在与否直接判定 v3.2 逻辑编入。比"读源码觉得应该对"可靠得多。
- 小坑：objdump 的助记符和寄存器之间是 **TAB**，grep 写 `movs r0, #53`（空格）会漏配，要写 `r0, #53`。

## 5. 逻辑/理解类的坑（最花时间）

### 5.1 需求极性做反（v1→v3）
第一轮把需求实现成“FILP 开 → ESC 变 grave”，用户真实意图后来演进成**默认就是 `` ` ``/`~`、F 模式还原真 ESC**，最终形态是 **ESC↔GRV 双向互换**。教训：这种"模式开关改变键义"的需求，先画**三态表**（默认/F 模式/按 Fn）让用户确认再动手。

### 5.2 厂商"数字行↔F 行"是**按 keycode 匹配**，不是物理位置
`case KC_1: if(filp)→KC_F1` —— 谁发 KC_1 谁参与，位置无关。我们的互换同理。推论：往数字格放 `KC_F3` 就不参与互换（Win 下恒 F3；**Mac+F 模式会被 `case KC_F3` 改去发音量↑**——厂商把 Mac 的 F 行映射成媒体键，容易踩）。

### 5.3 VIA 的 `CUSTOM(21)` 之谜
custom keycodes 由 `keyboard.json` 的 `keycodes[]` 按序从 `QK_KB_0(0x7E00)` 编号（FILP 在第 7 项=+6），VIA 显示编号有自身偏移，且**官方 VIA JSON 只命名了 7 个码**（BT/2.4G/USB）→ FILP 在 VIA 里就是无名 `CUSTOM(n)`。**结论：按功能码干活，不纠结显示数字。**

### 5.4 "刷完 0 层变成按 Shift 出 ~ 的 Esc" —— 不是我们的锅，是 QK_GESC
SRGBmods **内置默认键位**顶左放 `QK_GESC`，且该 fork 的 GESC 语义是 **Shift 或 GUI 按住时发 grave**（`process_grave_esc.c:29,63`：`shifted = mods & MOD_MASK_SG`），平时发 Esc → 看起来像"怪异的 Esc/~ 混合键"。bootmagic 清 EEPROM 后人人可见，极易误判成固件 bug。v3.1 把 default 层直接改成用户布局（`KC_GRV`/`KC_ESC`），误会根除。

### 5.5 `tap_code16` 在 process_record 里会被吞
v3 的 Shift+Bksp→PrtSc 用 `tap_code16(KC_PSCR)`，实测无反应（但键测工具能看到 PrtSc 事件）。改成与数字行互换**同款**的 `register/unregister` 配对后可靠。**经验：在 process_record_kb 内合成按键，用 register/unregister 自己管生命周期，别依赖 tap 快捷函数。**

### 5.6 Windows 根本不把 `Shift+PrtSc` 当截图（v3.2 根因）
`PrtSc` 与 `Shift+PrtSc` 是两个不同热键，后者在 Windows 默认**无绑定**（笔记本物理键实测复现）。v3.1 发 PrtSc 时 Shift 仍在报文里 → 系统看到 Shift+PrtSc → "无反应"。修复：发键瞬间**摘 Shift→注册 PrtSc→强制 `send_keyboard_report()` 打出干净按下沿→按原 L/R 位精确装回**（防止把另一侧没按的 Shift 变幽灵键）。**跨层坑：`get_mods()` 在这个 fork 直接等于 real_mods，没有单独的"物理层"API 可查，保存/恢复必须自己做精确位运算。**

### 5.7 指示钩子不吃全局亮度（v3.3 根因）
`rgb_matrix_indicators_advanced_kb` 是**直写帧缓存**的旁路，QMK 不做 val 缩放 → 红灯/白闪此前恒 255 满亮、和亮度旋钮脱钩。想要"跟随亮度+偏移"只能自己算（`hs_ind_val()`）。另注：该钩子仅在**有效果在渲染**时运行，mode 关掉（NONE）时指示也不出现。

## 6. 睡眠/唤醒与 GESC 的关系（专问解答）

**结论先行：右半久置无反应与 GESC 完全无关，是电源管理（LPWR）链路的回归 bug。**

- **GESC 是什么**：纯按键处理链里的一个 magic keycode（`QK_GRAVE_ESCAPE=0x7C29`），在 `process_grave_esc()`（位于 `process_record_kb` 之后的全局处理链）把同一个键解读成 Esc 或 grave。**它不碰电源、不碰唤醒、不碰分体通信**，跟"右半睡死"零关系。
- **右半唤醒/失灵的真实机制**（SRGBmods 改动 vs 官方）：
  1. `lpwr_is_allow_timeout_hook()`：官方版 `DEVS_USB→return false`（USB 下永不深睡，两半皆然）；SRGBmods 改成 `DEVS_USB && is_keyboard_master()`——**从半(右)在 USB 模式下也被允许进 LPWR 深睡**。
  2. SRGBmods 新增 `lpwr_is_allow_presleep_hook()`：睡前提 RPC 0xAA，两半把**分体 UART 的 TX/RX 脚改成品开漏**（省电），唤醒靠 `suspend_wakeup_init_user()` 里 `usart_init()` 恢复。
  3. 一旦唤醒路径没完整跑通（或从半睡了而主半没感知），表现就是：**右半按键全无反应，必须重新插拔左右连接线**——正是实测症状。
  4. 厂商自家 readme 还承认另一个设计性限制：**深睡期间只有左半能唤醒整机**（主半停止轮询从半矩阵，右半按键叫不醒）。
- **我们的修复演进**：v2 把 1. 恢复官方条件 → **USB 模式两半都不深睡**（有线症状根除）。v4（应"出厂两半都能唤醒"的反馈）：`lpwr_is_allow_timeout_hook()` 直接恒 `return false` → **无线也不再进 LPWR**，两半任意键随按随醒，行为与出厂一致；代价按 SRGBmods 自家 readme 口径：待机从"数月"降为"数周~月"（RGB 2 分钟超时、蓝牙 30 分钟断连等浅睡机制不受影响）。
- **深睡机制深挖（v4 决策依据，全部来自代码 diff）**：
  1. 每半 MCU 深睡时只给自己那侧的矩阵行挂唤醒 EXTI（`lpwr_wb32.c lpwr_exti_init`）→ 右半按键**能**唤醒右 MCU；
  2. 但 QMK 分体传输是**主拉从应**（master-initiated RPC），从半醒来后链路上没有自发流量 → 主半（左）永远收不到边沿 → 整机看起来"右半叫不醒"。**这是协议方向问题，不是硬件极限**；
  3. 更老的 hangshengkeji/出厂谱系里，串口唤醒边沿被归为 `LPWR_WAKEUP_UART`，而 `lpwr_stop_cb` 对该分类的处理是"再睡回去"（防模块心跳误唤醒）。**新验证**：SRGBmods 版虽然给分体 RX（A10）重挂了 BOTH_EDGES，但该 fork 里 `UART_RX_PIN` 默认值就是 **A10**（键盘 config 只定义了 `SERIAL_USART_*`，UART 驱动宏落到同名默认）——`palcallback` 的 `case PAL_PAD(UART_RX_PIN)` 仍然活着（`LPWR_UART_WAKEUP_DISABLE` 全树未定义），所以链路边沿会被分类成 UART 唤醒 → 照样"睡回去"。**最后一跳在两代谱系里都是双重封死的**：从半不自发说话 + 主半把 UART 分类的唤醒吃掉。
  4. 理论上存在保续航的两全方案，但要**三件套**：从半唤醒后自发 ping + 主半把"UART 分类唤醒"改成可唤醒（或改挂分类钩子 `palcallback_cb`）+ 重新验证模块心跳误唤醒（当年"30 分钟命令吵醒设备"的坑就是这么来的）。且该 config 引脚宏族互相重叠（UART/SERIAL_USART 都落 A9/A10），需实测确认链路到底走哪组脚。风险不小，属实验特性，未默认启用。
- **一句话总结**：右半无反应 = 新固件"深睡省电"策略的副作用；已用 v4 关闭深睡恢复出厂行为；GESC 从头到尾无辜。

## 7. 工程环境小坑速记

- `qadd8()` 在 split65.c 不可见（`quantum/util.h` 未传递包含）→ 编译期 `-Werror=implicit-function-declaration` 直接 fail；改 `(uint16_t)` 手动饱和。
- `keyboard.json` 的 `bootmagic.matrix`：官方仓库 `[0,0]`（实际无效位）vs SRGBmods `[1,0]`（真=左上 ESC/右半 7）——又是一个"信 readme 不如信代码"。
- 官方仓库源码与新树 `.c` 有 ±90 行漂移（新增 suspend/电池钩子）：移植补丁前**必 diff**，只带最小改动。
- 工具习惯：`find /` 会超时；跨全盘搜索前先限定家目录。

## 8. 复现清单（换电脑重建环境）

```bash
# 1) 源码树（SRGBmods 自带 Split65+WB32+wireless）
git clone --depth 1 https://gh-proxy.com/https://github.com/SRGBmods/EpomakerQMK.git Split65-firmware
cd Split65-firmware
git config url."https://gh-proxy.com/https://github.com/".insteadOf https://github.com/
# 2) Python（venv + qmk CLI，走 pip 镜像）
/usr/bin/python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt qmk && qmk config user.qmk_home=$PWD
# 3) 编译器（用户执行）
sudo apt-get install -y gcc-arm-none-eabi libnewlib-arm-none-eabi
# 4) 应用补丁（split65.c 六处 + keymap.c 两处，见 §1 与刷入指南附录 C~C5）
# 5) 编译（子模块首次由 make 自动 init）
make epomaker/split65:default
# 产物 .build/epomaker_split65_default.bin → cp 到 /mnt/c/... → QMK Toolbox 刷两半
# Windows 首次：Zadig 给 WB Device in DFU Mode(342D:DFA0) 绑 WinUSB
```

验收基线：v3.3（SHA `7764dabf…`）全功能实测通过：默认 `` ` ``/~、F 模式=真 Esc+13 键红灯（亮度联动+2档）、Fn+顶左=真 Esc、Shift(先)→Backspace=截图、Caps/Win 红、极限白闪、右半不再冻结/睡死。v4（SHA `e8118285…154cfa5f`，74436 字节）额外验证点：无线久置后**右半第一键即响应**、续航感知。

## 6.5 错误推断复盘："右半自带电池/自己渲染"（2026-09-15 修正）

排查链路故障时，我先后基于四条间接证据推断"右半有自己的电源并本地渲染灯效"：①`lpwr_is_allow_presleep_hook`/`0xBB/0xCC` 操作从半 LED 电源轨 GPIO（**有开关权 ≠ 有供电源**）；②同一份固件两半都读电池 GPIO（其实引脚在从半悬空）；③"数据线好的坏线右半不亮"当时被解读为"MCU 活着⇒有电源"（实际 MCU 由残余供电苟活、灯带大电流先塌）；④行业先验（三模分体≈双电池，类似 Keychron）。全部被一条实测推翻：**左半唤醒瞬间右半灯效即恢复且丝滑跟随——右半灯是主半单链画的，右半 MCU 根本不参与渲染；拔线右半全灭说明其无可用电池**。教训：①"能亮"≠"本地智能"，WS2812 链是纯硬件移位寄存器，一根数据线+电就能亮；②分体键盘先弄清"谁画灯、谁供电"再谈诊断逻辑；③我的错误推断把 v5 诊断灯做成了"绿常亮+对端可能睡"的误报模型，v5.1 才收敛成状态机。留给社区：遇到"半边行为异常"，先分清**数据路径**（UART/矩阵同步）与**显示路径**（灯链），它们物理独立。
