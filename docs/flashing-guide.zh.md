# EPOMAKER Split65 刷入指南（含备份 / 防变砖 / 救砖）

> 适用固件：**本仓库的修改版固件（当前 v5，A/B 两版）**。功能：`Esc↔\`` F 模式互换、Shift+Backspace=PrtSc、F 模式红灯排、Caps/Win 红、亮度极限白闪、**链路自诊断灯（v5 新增）**。
> 目标：`epomaker/split65:default` ｜ MCU：`WB32FQ95` ｜ 引导：`wb32-dfu`（USB‑DFU 在 **ROM**）
> 设备：VID `0x342D` / PID `0xE4C6`
> 最后更新：2026-09-16（**v5.2 诊断灯终版：红=通信断 / 灭=正常 / 绿闪3下=恢复；移除黄灯**——从半 A7 感知不到链路供电、USB 下必误报。v5.1/v5/v4/v3.3 保留可下载）

---

## 0. 版本指纹（刷之前先核对，确保刷的是正确产物）

| 版本 | 大小 | SHA‑256 (.bin) |
|---|---|---|
| **v5.2-A**（单边唤醒/续航优先） | `74760` B | `1cf5b7a6d7e8f3e5cfc8c26fcd790cbeefa96f00626fe8023098fa6509ee2ac4` |
| **v5.2-B**（双边唤醒/体验优先，推荐） | `74752` B | `6d3f5d32235cffa6568595f2a3e5762f8fe5c0b5322acd8d0864ddfca88cbe9c` |

产物在 Releases（含 `.hex` 与 `SHA256SUMS.txt`）；自建见 README"自行构建"（同一份源码，B 版加 `LINK_WATCH_ALWAYS=yes`）。
v5.2 = v4 功能 + Ctrl 链路诊断（红/灭/绿闪，附录 E）+ 提示灯=灯效+1档封顶。**v5/v5.1 为废案**（绿灯噪音/黄灯误报），已撤下不在 releases。历史线：v3.3=A 线、v4=B 线。

核对命令（在 WSL 里）：
```bash
sha256sum <QMK>/Split65-firmware/epomaker_split65_default.bin
```
> ⚠️ **EPOMAKER Split65 是分体式双 MCU 键盘（左半 + 右半）。两份固件是同一个 `.bin`，但左右两半都要各自刷一次。** 只刷一半会导致两半程序不一致 / 无法通信。
> 拓扑（实测）：**左半 = master**，有两个 USB-C（一个连电脑、一个连接右半的链路）；**右半单独插电不能独立使用**（它只是从半）。单用只可单插左半（右半会没字）。

---

## 1. 必读：为什么"几乎不会真变砖"

- WB32 的 **USB‑DFU 引导程序烧在芯片 ROM 里**（地址 `0x1FFFE000`），固件刷的是 **App 区（`0x08000000` 起）**。刷 App **不会、也无法**擦掉 ROM 里的 DFU。
- 只要还能让芯片进入 ROM DFU（按键/短接/Reset 键），就**永远可以重刷救回**。所以正常刷写风险很低。
- 真正会"砖"的情况极少：刷到一半断电、误擦 ROM/选项字节（本流程**不涉及**这些）。用本指南的 App 刷写不会触发。

**唯一要小心的物理点**：右半背后有个**电源/模式开关**（RShift 键帽后面）。刷完一定要**拨回"上"位**，否则右半不开机（不是刷坏，是没供电/在关断位）。

---

## 2. 工具与路线（给你选了**风险最低、操作最简单**的：Windows 图形化）

### ✅ 主路线：Windows 上用 QMK Toolbox（推荐）
- QMK Toolbox 自带/支持 WB32 的 `wb32-dfu-updater`。全程在 Windows 原生访问 USB，**不需要**在 WSL 里做 USB 透传，最稳。
- 下载：QMK Toolbox <https://github.com/qmk/qmk_toolbox>。若普通版不识别 WB32，使用 Glorious 提供、内置 WB32 支持的 QMK Toolbox（见 <https://www.gloriousgaming.com/blogs/guides-resources/gmmk-2-qmk-installation-guide>）。

**关键衔接（很多人卡这）：Toolbox 在 Windows 端，`.bin` 在 WSL 端，要先拷到 Windows 能打开的位置：**
```bash
# 在 WSL 里执行，把用户名换成你自己的
cp <QMK>/Split65-firmware/epomaker_split65_default.bin \
   /mnt/c/Users/你的用户名/Downloads/
```
> Windows 里对应的路径就是 `C:\Users\你的用户名\Downloads\epomaker_split65_default.bin`。

### 🧑‍💻 备用路线：WSL/Linux 命令行（附录 A）
适合喜欢终端的人，但需要额外装 `wb32-dfu-updater_cli` 并用 **usbipd‑win** 把 DFU 设备透传进 WSL2，步骤多、更易失败。**不推荐作为首选。**

---

## 3. 刷前备份（务必做，三层）

**① 官方出厂固件（回退用）**
本固件所基于的 fork 在 release 里提供了这些商用键盘的**原厂固件文件**，用于回退：
<https://github.com/carlosedp/qmk_firmware/releases/tag/0.31.2>
把对应 Split65 的原始 `.bin` 下载并**存到 Windows 本地**备用。

**② 你现在的键位配置（VIA）**
- 打开 **VIA**（<https://usevia.app> 或桌面版），连上键盘，右下角齿轮里 **Export** 当前配置，保存 JSON。
- 特别是记牢你现在怎么用的：`Fn 层 Ctrl 位 = CUSTOM(21)`（切换数字行/F 行）、`ESC` 键在哪个位置等。

**③ 关于"设置会不会丢"**
- 本键盘 EEPROM（VIA 的 8 层键位、宏、RGB 记录）放在**外置 SPI Flash**；DFU 刷 App 本身**不碰它**。
- 但经代码核实（`quantum/bootmagic/bootmagic.c`）：凡是用 **hold ESC / hold 7 + 插线**（bootmagic）方式进 DFU，**每次都会 `eeconfig_disable()` 清空持久设置**，回到固件默认层。
- 所以：**必须先在 VIA Export 键位 JSON**，刷完再 Import 回来。（短接焊盘进的是 ROM DFU，不清设置，但首次刷右半本来就得短接。）

---

## 4. 防变砖 Checklist（刷前逐条确认）

- [ ] 已下载并保存**官方原始固件**（§3①）。
- [ ] 已在 VIA **导出键位 JSON**（§3②）。
- [ ] 已把要刷的 `epomaker_split65_default.bin` **拷贝到 Windows 可访问路径**（§2）。
- [ ] SHA‑256 与你所选版本一致（§0：v5.2-A `1cf5b7a6…` / v5.2-B `6d3f5d32…`）。⚠️ 桌面/下载文件夹里 v5、v5.1、v5.2 文件名相似，认准 v5.2。
- [ ] 用**机箱后置 USB 口 / 好的数据线**（能传数据、供电稳），**不要用劣质线或免驱集线器**。
- [ ] 刷写过程中**不拔线、不断电、不锁屏休眠**（先把 Windows 电源计划"不进入睡眠"）。
- [ ] 明确**左右两半各刷一次**，且刷**同一个 bin**。
- [ ] 记住右半 RShift 后开关：**刷完拨回"上"**。
- [ ] 不要给 `wb32-dfu-updater_cli`/Toolbox 指定 ROM 区或选项字节区——只刷 App（默认就是 App）。

---

## 5. 正常刷入流程（逐步）

> 通用套路：让某一半进入 **DFU** → 工具识别到设备 → 刷同一个 `.bin` → 复位 → 再做另一半。
> 每半进入 DFU 的方法不同，见下。

### 5.1 先准备 QMK Toolbox
1. 打开 Toolbox，菜单 `Options → Local Firmware` 里 **File** 选到你拷到 Windows 的 `epomaker_split65_default.bin`。
2. 芯片/Bootloader 不用手动选（WB32 会被自动识别为 DFU）。**不要**勾任何"擦除全部/选项字节"之类选项。
3. **Windows 驱动（关键，首次必做）**：设备进 DFU 后，Toolbox 若提示
   `WB32 DFU device ... NO DRIVER ... should be WinUSB. Flashing may not succeed.`
   说明该 DFU 设备没绑到 **WinUSB**，`wb32-dfu-updater_cli`（走 libusb）会连不上。用 **Zadig** 修：
   - 下载 <https://zadig.akeo.ie/> → **Options → List All Devices** → 选 `WB Device in DFU Mode (342D:DFA0)` → 右侧驱动选 **WinUSB** → **Install Driver**（等绿色成功）。保持键盘处于 DFU、别拔线。
   - 装好后回到 Toolbox 就能看到设备正常 → Flash。若之前那次其实已经刷成功（忽略了警告），可不必再折腾。

### 5.2 刷【左半】
1. 左半**先拔掉 USB**。
2. **按住左半左上角的 `ESC` 键不放**，同时把 USB 线插入左半 → 进入 DFU（ROM）。
3. 若键盘连了左右连接线，插哪半都行；DFU 一般挂在直连 USB 的那半。**建议：刷左半时把左右连接线暂时拔掉，避免干扰。**
4. Toolbox 里 `Device` 下拉会出现 DFU 设备 → 点 **Flash (F5)** → 等待 " flashing OK / Done"。
5. 完成后设备自动复位。**拔掉 USB，松开 ESC。**

> 如果"按住 ESC 插线"没进 DFU：改用物理 **Reset 键**（PCB 背面复位按键）——先插 USB，再按一下 Reset 即可进 App 启动；进 DFU 则"按住 ESC + 按 Reset"或"按住 ESC + 重新插拔"。以"能刷进去、能被 Flash"为准。

### 5.3 刷【右半】

> ⚠️ 关于配图：官方 readme 末尾写了 `![Howto](./howto.jpg)`，但经 GitHub API 核对，该 `howto.jpg` **根本没有被提交进仓库**（carlosedp、SRGBmods 的 `keyboards/epomaker/split65/` 目录里都没有图片文件）。所以你在仓库里找不到它是正常的——**这是一条死链，没有官方照片**。原文可在浏览器里看：
> <https://github.com/carlosedp/qmk_firmware/blob/master/keyboards/epomaker/split65/readme.md>

右半没有"按 ESC 进 DFU"的实体键，用硬件方式。先试最省事的，不行再短接。

**方法 0（先试这个，最可能不用找焊盘）——只靠那个开关：**
1. 右半**先拔 USB**；把 **RShift 键帽后面那个开关拨到"下"位**（你已经找到它了）。
2. 直接把 USB 插入右半 → 看 QMK Toolbox / `lsusb` 是否出现 DFU 设备。
   - 很多 carlosedp WB32 板子这个开关"下"位就是把 BOOT/DFU 脚接地，**只拨开关就能进 DFU**。若成功，跳到 §5.3 末尾的刷写即可。
   - 若没出现 DFU，再用下面的"方法 A 短接"。

**方法 A（通用兜底）——短接空格位下方的两个焊盘：**
1. 右半**先拔 USB**，RShift 后开关拨"下"。
2. 拔掉**空格键的键帽和轴（热插拔直接拔）**，露出 PCB 上的**空格位**。
3. 关键：原文说的"the two holes beside the central switch hole / DFU pads behind the switch position" = **空格那颗 MX 轴座正下方、PCB 上那两处金属触点**（就是原来插轴的两根针脚焊盘，中间还夹着一个固定柱孔）。这俩触点在开机瞬间被短接时，会把该列/行的矩阵脚拉低，等于按住那颗"BOOT 键"，从而让 ROM 进 DFU。
4. 用**镊子/回形针同时搭住这两个触点**，**保持短接**的同时把 USB 插入右半，2~3 秒后松手 → 进入 DFU。
5. 找不到明显裸露焊盘时：把板子**翻过来看背面**，焊盘/过孔可能在**背面**空格位对应处；用强光+放大镜，两触点通常相距几毫米。

**方法 B（便捷，仅当右半已跑本/兼容固件后）：**
- 开关拨"下"，**按住数字 `7` 键**同时插入右半 USB 即可进 DFU（`7` 就是右半那颗被复用成 BOOT 的键，等价于方法 A 的短接）。首次仍建议用方法 0/A。

**右半进 DFU 后统一操作：** QMK Toolbox 选中设备 → 载入 `epomaker_split65_default.bin` → **Flash (F5)** → 完成复位 → **拔 USB** → **把 RShift 后开关拨回"上"位！** 装回空格键帽和轴。

### 5.4 收尾
- 两半都刷完后，接好**左右连接线**，插上 USB（或切无线），确认能正常打字、左右都响应。

---

## 6. 刷后验证（v3 行为）

1. **键位说明（v3.1 起）**：我们把固件**编译内置的 default 键位**直接改成了你的布局（layer0 顶左=`` ` ``，Fn 层顶左=`Esc`，Mac 两层同理），bootmagic 清 EEPROM 后回落的就是这套，不会再出现 `QK_GESC`("按 Shift 变 ~ 的 Esc")。若你有其它 VIA 自定义，仍需重新 Import。
2. **基础**：打字正常；RGB、三模(有线/蓝牙/2.4G)、左右半通信正常。
3. **ESC↔`` ` `` 双向互换（v3 语义，按 keycode 不按位置）**：任何格子里放的是 `Esc` 还是 `` ` ``，平时都按字面输出；**F 模式(FILP 开)且未按 Fn 时两者互换**。以你当前摆放（0层顶左=`` ` ``，1层顶左=`Esc`）为例：
   | 操作 | FILP 关 | FILP 开 |
   |---|---|---|
   | 按顶左（0层 `` ` `` 格） | `` ` `` / `~` | **真 ESC** |
   | 按住 Fn+顶左（1层 Esc 格） | 真 ESC | 真 ESC（按 Fn 时豁免互换） |
4. **F 模式其余**：数字行 = F1~F12；ESC+数字+`-`+`=` 共 13 键亮红灯；再按 Fn+Ctrl 关闭后熄灭。Win/Mac 层一致。**全部提示灯（红灯排/白闪/Caps/Win/诊断）亮度 = 当前亮度+1 档（封顶最亮）**：调暗灯效时指示跟着变暗但最暗时仍可见（不会全黑看不见）。
5. **截图**：**先按住 Shift 再按 Backspace** = PrtSc（Win11 默认弹截图工具/存剪贴板取决于系统设置）；先按 Backspace 再补 Shift 仍是普通退格。注意该组合在 Linux X11 语义为 SysRq（Windows 无此问题）。
6. **指示灯**：CapsLock → Caps 键红灯；`Fn+Win` 锁 Win → Win 键红灯。
7. **亮度极限**：调最亮 → `↑` 键白闪两下；调最暗 → 全灯熄灭（**右半不再卡帧**）且 `↓` 键白闪两下。
8. **DFU 回归**：拔插验证"按住左半 ESC / 右半按住 7（开关拨下）"仍能进 DFU（重映射不影响，bootmagic 查的是开机瞬间的裸矩阵）。
9. **唤醒（v4）**：无线放置十几分钟后，**直接按右半任意键**应立即有反应（不再需要先按左半唤醒）；若出现"右半第一键丢失"或续航明显异常，报我回滚。

---

## 7. 常见问题（FAQ）

- **Toolbox 里看不到设备**：多半没真正进 DFU。重做 §5.2/§5.3（右半务必短接两焊盘**同时**插线）；换 USB 口/线；WSL 与 Windows 别抢设备（本主流程全程 Windows，不涉及 WSL）。
- **刷完 ESC 不变成 `` ` ``**：VIA 里那一格必须是**真 `KC_ESC`**。SRGBmods 默认层顶左是 `QK_GESC`（Grab Escape），bootmagic 清 EEPROM 后回默认层时尤其容易踩到——Import 你的键位或手动改成 `Esc` 即可。
- **Toolbox 读不到 `.bin`**：确认文件已在 `C:\Users\…\Downloads\`（§2 的 `cp` 到 `/mnt/c/…` 步骤）。
- **提示 `NO DRIVER … should be WinUSB` / 刷不进去**：Windows 没给 DFU 设备绑 WinUSB。用 **Zadig** 给 `WB Device in DFU Mode (342D:DFA0)` 装 **WinUSB** 驱动（见 §5.1 步骤 3）。设备已能显示 `342D:DFA0` 说明**进 DFU 成功**，只是缺驱动，装上即可刷。
- **日志出现 `No DFU capable USB device available` 但结尾又显示 `Flash complete`**：**其实没刷进去**（"Flash complete" 是 Toolbox 无条件打印的，别被误导）。根因仍是缺 WinUSB 驱动，`wb32-dfu-updater_cli`(libusb) 打不开设备。按上一条用 Zadig 装 WinUSB 后重刷；成功时日志会显示真正的 erase/program 进度，而不是 `No DFU capable…`。
- **刷完右半完全没反应**：RShift 后的开关还在"下"位——**拨回"上"**。
- **左右半连上后互相没反应 / 一半不能用**：两半固件版本不一致，或连接线没插好。**把两半都重刷成同一个 `.bin`**，检查连接线与方向。
- **想"两边都能唤醒键盘"**：本固件默认深睡只有左半能唤醒。改 `keyboards/epomaker/split65/split65.c` 里 `lpwr_is_allow_timeout_hook()` 最后 `return true;` 改 `return false;` 重新编译再刷（代价：无线待机电流更大、续航变短）。
- **报 `wb32-dfu-updater_cli not found`**：只在附录 A（WSL 命令行）会遇到，见附录 A 安装步骤。

---

## 8. 救砖指南（分级，从易到难）

> 核心结论：**DFU 在 ROM，进得去 DFU 就救得回。** 99% 的"刷坏了"都属于第①/②级。

### ① 能进 DFU（最常见，等于没砖）
重做 §5.2/§5.3 让它进 DFU → Toolbox 重新 **Flash** 本 `epomaker_split65_default.bin`；或直接**回退官方**：载入 §3① 下载的原始 `.bin` 刷回。

### ② 刷完没反应 / 像半砖
- 先排除**右半开关没拨回上**（§7）。
- 再反复尝试进 DFU：
  - 左半：**按住 ESC + 插 USB**；或插着 USB 时**按 PCB 背面 Reset 键**再配合按住 ESC。
  - 右半：**短接 DFU 两焊盘 + 插 USB**（方法 A 最可靠，和当前是否跑坏固件无关，因为是 ROM 检测短接）。
- 一进 DFU（Toolbox 能看到设备），就重刷。

### ③ 完全枚举不到设备
- 换电脑/换 USB 口/换线，排除供电与线材。
- 用**物理 Reset 键** + 短接组合再试。WB32 靠 ROM‑DFU，只要芯片没物理损坏，短接进 DFU 应始终可用。
- 极少数需要 **SWD 调试器**（SWDIO/SWCLK 焊盘，配合 openocd/pyocd 的 WB32 支持）。这属于硬件级，普通刷写**不会**把你逼到这步；优先靠上面 ROM‑DFU 恢复。

### ④ 想彻底回原厂
§3① 的 release 里拿 Split65 原厂 `.bin`，按 §5 正常流程刷回即可（左右两半各一次）。

---

## 附录 A：WSL/Linux 命令行刷写（备用，非推荐主流程）

WSL2 要能访问 DFU 设备，需 **usbipd-win** 把设备透传进来：
```powershell
# Windows PowerShell(管理员)
winget install usbipd
usbipd list                 # 找到 DFU 设备的 BUSID（进 DFU 后才会出现）
usbipd bind --busid <BUSID>
usbipd attach --wsl --busid <BUSID>
```
在 WSL 里安装工具并刷：
```bash
# 安装 wb32-dfu-updater_cli（Ubuntu 无 apt 包，从源码编）
sudo apt-get update && sudo apt-get install -y git cmake build-essential libusb-1.0-0-dev
git clone https://github.com/WestberryTech/wb32-dfu-updater && cd wb32-dfu-updater
cmake -B build && cmake --build build
sudo cp build/wb32-dfu-updater_cli /usr/local/bin/
# 让设备进 DFU 后：
wb32-dfu-updater_cli -l                                  # 应显示 Found DFU
wb32-dfu-updater_cli -t -s 0x08000000 -D epomaker_split65_default.bin
wb32-dfu-updater_cli -R                                  # 复位
```
或直接用 QMK 的 flash 目标（它内部就是上面这条，会一直等 "Found DFU"）：
```bash
cd <QMK>/Split65-firmware && . .venv/bin/activate
make epomaker/split65:default:flash      # 先让对应半进 DFU
```

---

## 附录 B：如何重新编译（改了代码后）

```bash
cd <QMK>/Split65-firmware
. .venv/bin/activate                 # 里面有 qmk CLI，已配置 user.qmk_home
make epomaker/split65:default        # 产物在 .build/，并自动拷到仓库根目录同名 .bin
```
依赖说明（本机现状）：`arm-none-eabi-gcc 10.3.1`（已装）、QMK CLI 1.2.0（在 `.venv`）、子模块 `lib/chibios`/`lib/chibios-contrib` 等（已拉取，走 gh-proxy）。

---

## 附录 C：v2 改动 diff（相对 SRGBmods 原始 split65.c）

1) ESC 键重映射（反相版，`KC_EQL` 与 `KC_FILP` 之间）：
```c
        case KC_ESC: {
            if (confinfo.filp || (layer_state & ((1u << _FL) | (1u << _MFL)))) {
                return true;                 // F 模式 / 按住 Fn → 真 ESC
            }
            if (record->event.pressed) {
                register_code(KC_GRV);       // 默认 → ` ；Shift 时由主机组合出 ~
            } else {
                unregister_code(KC_GRV);
            }
            return false;
        } break;
```
2) `KC_FILP` 分支：翻转后新增 `0xF0` RPC，把 `confinfo.filp` 同步给另一半（跨半红灯排用，从半不写自己的 EEPROM）。
3) 指示钩子 `rgb_matrix_indicators_advanced_kb()`：
   - `confinfo.filp` 指示：原"LED32('0') 白灯"一行 → **LED22~34 涂红**（= `6..1`、`ESC`、`7..0`、`-`、`=` 共 13 键）。
   - CapsLock / Win 锁指示灯：`0x20,0x20,0x20`(暗白) → `0xFF,0,0`(红)。
4) 亮度键：`RM_VALU` 到达 `RGB_MATRIX_MAXIMUM_BRIGHTNESS(150)` → ↑(LED54) 白闪 250ms×2；`RM_VALD` 到底 → 清帧 + ↓(LED66) 白闪；**删除**了原误用的"速度阈值闪烁"与"最暗拉 LED 电源轨"（冻结根因；省电交由 suspend 路径处理）。
5) `lpwr_is_allow_timeout_hook()`：`DEVS_USB && is_keyboard_master()` → 恢复官方 `DEVS_USB`——USB 模式下从半也永不深睡（修"右半久置失灵"）。无线模式行为不变。

## 附录 C2：v3 追加改动

- **ESC↔GRV 双向互换**（替换 v2 的单向 ESC 重映射）：`case KC_ESC` 在 FILP 开且未按 Fn 时发 `KC_GRV`；新增 `case KC_GRV` 同条件发 `KC_ESC`；其余情形完全按 VIA 字面输出。数字行/F 行互换不受影响。
- **Shift+Backspace → PrtSc**：新增 `case KC_BSPC`，按下瞬间检测 Shift 已按住则 `tap_code16(KC_PSCR)` 并吞掉本次按键，用 `static bool pscr_sent` 配对 release 防退格卡键；未按 Shift 的 Backspace 路径零改动。
- 反汇编指纹：`process_record_kb` 内 `movs r0,#53`（ESC→grv）、`movs r0,#41`（grv→ESC）、`movs r0,#70`（PrtSc）、`and #16`/`and #10` 守卫 ×2。

## 附录 C3：v3.1 修订

- **PrtSc 触发方式重写**：v3 的 `tap_code16` 在 process_record 内可能被吞（Shift+Bksp 无效的疑因），改为与"数字行↔F 行"同款、已实测可靠的 `register_code16(KC_PSCR)` / `unregister_code16` 配对（`pscr_down` 标志对齐 press/release）。触发条件不变：**先按住 Shift 再按 Backspace**。
- **default 键位修正**：`keymaps/default/keymap.c` 四层顶左改为 _BL/_MBL=`KC_GRV`、_FL/_MFL=`KC_ESC`，移除 SRGBmods 的 `QK_GESC`（该 fork 的 GESC 语义 = Shift/GUI 按住时发 grave，即"按 Shift 变 ~ 的 Esc"，曾造成"默认层被改"的误会——它是编译内置默认层，与 VIA/EEPROM 无关）。

## 附录 C4：v3.2 PrtSc 修复（Shift+PrtSc ≠ PrtSc）

实测发现 Windows 把 `Shift+PrtSc` 当作另一个快捷键（笔记本实测无操作），而旧实现发 PrtSc 时 Shift 仍在报文里 → 截图不触发。现改为：按下时 `get_mods` 摘出实际按住的 Shift 位（L/R 精确保存）→ `del_mods` → `register_code16(KC_PSCR)` → **`send_keyboard_report()` 强制刷出无 Shift 的干净 PrtSc 按下边沿** → `add_mods` 原样装回（不留幽灵修饰、不误伤另一半 Shift）；释放时 `unregister_code16(PSCR)` + 再刷一次。反汇编已确认此调用序列编入 `process_record_kb`。

## 附录 C5：v3.3 指示亮度联动

新增 `hs_ind_val()`：`指示亮度 = min(rgb_matrix_get_val() + 2×RGB_MATRIX_VAL_STEP, RGB_MATRIX_MAXIMUM_BRIGHTNESS)`（当前数值即 +60、封顶 150）。应用于：F 模式红灯排、CapsLock 红、Win 锁红、↑/↓ 亮度极限白闪。QMK 的 indicators 钩子直写帧缓存、本就不受全局亮度缩放，故此前指示恒为满亮——现在主动跟随：灯效调暗指示跟着暗、调最暗时键灯熄灭而指示仍可辨（不会看不见，也不会晚上瞎眼）。

## 附录 C6：v4 唤醒策略（"只有左半能唤醒"的真相与解法）

- **GESC 与此无关**：`QK_GESC` 只是 process_record 链里一个"一键两码"的 keycode（`process_grave_esc.c`），不触碰电源/唤醒/分体通信。
- 右半唤不醒的真凶是 SRGBmods 的 **LPWR 深睡策略**：两半深睡后，主半停止轮询；QMK 分体协议里**从半只应答、不主动发**，于是右半按键只能唤醒右 MCU，叫不醒左半 → 表现为"必须先按左半"。厂商 readme 把"只左半可唤醒"当作特性写明了，这是**取舍不是硬件极限**；出厂固件没有这套 LPWR，两半随按随醒（用户记忆正确）。
- **v4 解法**：`lpwr_is_allow_timeout_hook()` 恒 `return false` → 两半永不进 LPWR（保留 chibiOS 浅暂停与 RGB 2 分钟超时）。效果：任意键即按即应；代价：无线待机从数月降到数周~月（SRGBmods 自家 readme 给出的同选项）。
- 若日后想"数月待机+两侧可醒"兼得：需"从半醒后自发 ping + 主半 UART 唤醒分类放行 + 防模块心跳误唤醒回归测试"三件套（该 fork 的 UART/分体串口引脚宏重叠在 A9/A10，还需实测确认链路走哪组脚），风险=帧失步/夜间误唤醒，属实验特性。需要时找我评估。

---

## 附录 D：关键地址 / 引脚速查

| 项 | 值 |
|---|---|
| App 固件基址 | `0x08000000` |
| ROM DFU 引导地址 | `0x1FFFE000` |
| Bootloader | `wb32-dfu`（USB‑DFU in ROM） |
| bootmagic 进 DFU 键 | 矩阵 `[1,0]` = 左半左上角 **ESC** |
| 左/右半判定脚 | `B9`（handedness，自动） |
| 左右半通信 | UART（`SERIAL_USART`） |
| 外置 SPI Flash | 片选 `C12`（存 EEPROM / VIA 键位 / RGB 记录，刷 App 一般不动） |
| VID / PID | `0x342D` / `0xE4C6` |

## 附录 E：v5.2 链路诊断灯（左右 Ctrl，终版）

**架构**：RGB 为单链、全部由左半（主）MCU 绘制；连接线四组独立导线：5V（给右半整体供电）、GND、UART（键数据）、WS2812 数据线。右半 MCU 无本地电池，"拔线右半全灭"是必然。

| 状态（A/B 一致） | 表现 |
|---|---|
| 通信正常 | **灭** |
| 通信断（拔线/UART坏/从半死） | **红**：运行中断→闪 3 下→常亮；开机即断→直接常亮 |
| 断→恢复 | **绿闪 3 下 → 灭** |

判据：2s 内无成功 `0xF1` 交换=断。

**为什么没有黄灯、也测不了灯链故障**：
1. 黄灯原判据"两半 A7 充电感不对称"——实测从半 A7 接的不是链路 5V 感（悬空恒 0），USB 下永远误报 → v5.2 移除。
2. WS2812 链单向无回读（无 ACK/无 sense），"UART 好但灯链死"固件原理性不可测。**灯效本身就是给人看的回读**。真值表：
| 你看到的 | 结论 |
|---|---|
| 右半能打字、右半灯也动 | 全好 |
| 右半不打字、左 Ctrl 红 | UART 断（或从半没电）——即使此时右半灯还在漂亮地动 |
| 右半不打字、右半全黑、左 Ctrl 红 | 供电+数据全断（或拔线） |
| 右半能打字、右半灯全黑 | 弱线供电不足——**无灯可报**，眼见即所得，换线 |

灯效模式=NONE/灯被关时所有指示（含诊断）不显示（QMK 钩子固有）。
## 参考链接
- QMK 刷写与 WB32 说明：<https://docs.qmk.fm/#/flashing>
- wb32-dfu-updater：<https://github.com/WestberryTech/wb32-dfu-updater>
- 原厂固件回退：<https://github.com/carlosedp/qmk_firmware/releases/tag/0.31.2>
- QMK Toolbox：<https://github.com/qmk/qmk_toolbox>

## 附录 C6：v5.1 修订

- 诊断灯从 `6/7` 挪到 `左Ctrl(4)/右Ctrl(64)`；绿常亮撤销，改**状态机**：入异常闪3下→常亮、恢复绿闪3下→灭、开机即异常直接常亮。
- 黄闪改为**仅主半判定并显示**（从半充电读数在缺电时不可信）。
- 所有提示灯亮度 `hs_ind_val()` 由 +2 档改为 **+1 档**（封顶 150）：更省电。
- 依据模型修正：右半无可用电池、灯链单链由主半驱动（详见附录 E、踩坑记录 §6.5 复盘）。
