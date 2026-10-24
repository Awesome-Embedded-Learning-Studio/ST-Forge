---
title: 04 — 编译与烧录（WSL · Linux）
---

# 04 — 编译与烧录（WSL · Linux）

环境装好了、模板结构也看过了,这一章咱们把「源代码怎么变成芯片里跑的程序」这条链路走通:编译出固件、烧进 Blue Pill、看见板载灯亮。走完这一遍,「我写的代码真在硬件上跑了」这个闭环就算打通了。Linux/WSL 这条路上的绝大多数步骤和 Windows 路线一样,差异主要在两点:`cmake` 不用带 `-G`,以及烧录前得先把 ST-Link 的 USB 权限理顺。

## 从源码到芯片,中间发生了什么

先把链路摆出来,后面每步都在这条链上走:

```
.c/.s 源文件 → 预处理 → 编译 → 汇编 → .o 目标文件 → 链接 → .elf → objcopy → .bin → 烧进 Flash
```

源文件经预处理、编译、汇编成 `.o`,链接器按链接脚本(02 章那个 `.ld`)把它们摆进芯片内存、产出 `.elf`,`objcopy` 再剥成纯二进制 `.bin` 烧进 Flash。`CMakeLists.txt` 里那个 `POST_BUILD` 的 `add_custom_command`,干的就是 `objcopy` 加打印 size。

## 编译:配置一次,然后 make

进模板目录,建 `build/` 子目录,在里面配置并编译:

```bash
cd /path/to/ST-Forge/project/0_template
mkdir -p build && cd build
cmake ..
make
```

注意这里和 Windows 路线的关键区别:Linux 下 `cmake ..` **不用带 `-G`**。Windows 上必须带 `-G "MinGW Makefiles"` 是因为 CMake 默认挑 Visual Studio 生成器;Linux 默认就是 Unix Makefiles,直接能 `make`,没这个坑。

`cmake` 这一步叫配置:检测编译器、解析 `CMakeLists.txt`、生成 `Makefile`。看到末尾 `-- Generating done`,配置就过了。然后 `make` 真正编译,会一路打印编译每个文件、链接 `.elf`、生成 `.bin`:

```
[ 94%] Linking C executable STM32F1.elf
Generating STM32F1.bin
   text    data     bss     dec     hex filename
   ...      ...     ...     ...     ... STM32F1.elf
[100%] Built target STM32F1.elf
```

那行 `text data bss dec hex` 是 `arm-none-eabi-size` 打的内存体检表,含义 02 章讲过(text 进 Flash,data/bss 进 RAM)。看到 `[100%] Built target`,编译就成了。改了源码之后再 `make`,CMake 增量编译,只重编动过的文件。

## 烧录:先把 USB 权限理顺

编译有了 `.bin`,接下来靠 OpenOCD 通过 ST-Link 写进芯片。但烧录之前,Linux/WSL 这边得先把 ST-Link 的访问权限搞定,否则 OpenOCD 连不上——这是 Linux 路线上比 Windows 多出来的一步。

原生 Linux 走了 [01 章](./01_environment_setup)的 udev 规则的话,权限已经永久放开,跳过即可。WSL 朋友得先在 Windows 侧把 ST-Link attach 进来,再跑权限脚本:

```powershell
# Windows PowerShell(管理员):把 ST-Link 透传进 WSL
usbipd wsl list
usbipd wsl attach --busid <BUSID>
```

```bash
# 回到 WSL,放开设备权限(模板里带的脚本)
cd /path/to/ST-Forge/project/0_template
./chmod_usb.sh
```

确认一下设备真能看到,再烧录:

```bash
lsusb | grep -i ST-LINK
# 应该看到:Bus 001 Device XXX: ID 0483:3748 STMicroelectronics ST-LINK/V2
```

接线也复查一遍:SWDIO、SWCLK、GND 接好,Blue Pill 的 **BOOT0 拨到 0**(从 Flash 启动),板子供电。然后在 `build/` 目录里跑:

```bash
make flash
```

它展开就是一条 OpenOCD 命令,咱们看它干了啥:

```bash
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c "program STM32F1.bin verify reset exit 0x08000000"
```

`-f interface/stlink.cfg` 指定 ST-Link 调试器,`-f target/stm32f1x.cfg` 指定 STM32F1 目标,`program ... verify reset exit 0x08000000` 是写、校验、复位、退出。成功的标志是这几行:

```
Info : STLINK V2J14S0 (API v2) VID:PID 0483:3748
Info : Target voltage: 3.2V
** Programming Started **
** Programming Finished **
** Verify Started **
** Verified OK **
```

看到 `** Verified OK **`,固件就稳稳写进去了,板子自动复位开始跑——PC13 那盏灯该一秒一闪了。要完全擦除芯片,`make erase` 走 OpenOCD 的 `stm32f1x mass_erase`。

## 烧录失败,最常栽在哪几个坑上

`Error: libusb_open() failed with LIBUSB_ERROR_ACCESS` 或 `Permission denied`,根因是 USB 权限没放开——这是 Linux 路线最高频的坑。原生 Linux 配 udev 规则,WSL 跑 `chmod_usb.sh`。

WSL 里 `lsusb` 压根看不到 ST-Link,根因是没在 Windows 侧 `usbipd wsl attach`。WSL2 看不见宿主 USB,这步漏了后面全白搭,而且每次重插或 WSL 重启都得重来。

`Error: target not halted` 或 `flash programming failed`,常见根因是 BOOT0 没拨到 0,或 SWD 引脚被程序占用。先查 BOOT0,再试降低 SWD 时钟(OpenOCD 配置里加 `adapter speed 1000`)。

还有个非技术的坑能让人怀疑人生:**USB 线是充电线不是数据线**。有些 Micro-USB 线只接了两根电源线,ST-Link 插上去没数据通路,换根能传数据的线就好。

## 命令速查

| 干什么 | 命令 |
| --- | --- |
| 配置(Linux 不用带 -G) | `cmake ..` |
| 编译 | `make` |
| 增量重编 | 改完源码直接 `make` |
| 完全重来 | 删掉 `build/` 重新配置编译 |
| 看 ST-Link 在不在 | `lsusb \| grep -i ST-LINK` |
| 放开 USB 权限(WSL) | `./chmod_usb.sh` |
| 烧录 | `make flash` |
| 擦除 | `make erase` |
| 看 Flash/RAM 占用 | `arm-none-eabi-size --format=berkeley build/STM32F1.elf` |

---

[上一篇:代码走读](./03_code_walkthrough) | [下一篇:调试方法 →](./05_debugging)
