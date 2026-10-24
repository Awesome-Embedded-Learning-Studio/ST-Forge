---
title: 04 — 编译与烧录
---

# 04 — 编译与烧录

环境装好了、模板结构也看过了,这一章咱们把「源代码怎么变成芯片里跑的程序」这条链路亲手走通:编译出固件、烧进 Blue Pill、看见板载灯亮起来。走完这一遍,嵌入式开发最让人有成就感的那个闭环——「我写的代码,真的在硬件上跑了」——就算打通了。

## 从源码到芯片,中间发生了什么

先把整条链路摆出来,后面每一步都是在这条链上走:

```
.c/.s 源文件 → 预处理 → 编译 → 汇编 → .o 目标文件 → 链接 → .elf → objcopy → .bin → 烧进 Flash
```

源文件先经过预处理(展开宏、处理 `#include`),再编译成汇编,汇编成 `.o` 目标文件;链接器把这些 `.o` 按链接脚本(02 章那个 `.ld`)摆进芯片的内存布局,产出 `.elf`;最后 `objcopy` 把 `.elf` 里要进 Flash 的部分剥成纯二进制 `.bin`,烧录器把它写进芯片的 Flash。`CMakeLists.txt` 里那个 `POST_BUILD` 的 `add_custom_command`,干的就是 `objcopy` 这一步外加打印 size。

## 编译:配置一次,然后 make

进模板目录,建个 `build/` 子目录,在里面配置并编译。Windows 上**必须带 `-G "MinGW Makefiles"`**——这个坑 01 章撂过,根因是 CMake 在 Windows 上默认挑 Visual Studio 生成器,不带 `-G` 就会生成 `.sln`、`make` 用不了。

```cmd
cd project\0_template
mkdir build && cd build
cmake -G "MinGW Makefiles" ..
make
```

`cmake` 这一步叫「配置」:它检测编译器、解析 `CMakeLists.txt`、生成 `Makefile` 和 `compile_commands.json`。看到末尾 `-- Generating done` 和 `-- Build files have been written to: .../build`,配置就过了。然后 `make` 才是真正的编译,会一路打印编译每个 `.c`、链接 `.elf`、生成 `.bin`:

```
[ 94%] Linking C executable STM32F1.elf
Generating STM32F1.bin
   text    data     bss     dec     hex filename
   ...      ...     ...     ...     ... STM32F1.elf
[100%] Built target STM32F1.elf
```

末尾那行 `text data bss dec hex` 是 `arm-none-eabi-size` 打的内存体检表,含义 02 章讲过(text 进 Flash,data/bss 进 RAM)。看到 `[100%] Built target`,编译就成了。改了源码之后,直接再 `make` 就行,CMake 会增量编译,只重编动过的文件,不用每次重新配置。

要是哪次改了 `CMakeLists.txt` 本身(比如加了编译选项),`make` 会自动感知并重新跑一遍配置,一般也不用手动 `cmake`。但要是配置出了怪问题,最干净的办法是删掉整个 `build/` 从头来——缓存的旧配置有时候会顽固地留着。

## 烧录:把 .bin 写进 Flash

编译有了 `.bin`,接下来靠 OpenOCD 通过 ST-Link 把它写进芯片。接线先确认无误:SWDIO、SWCLK、GND 三线接好,Blue Pill 的 **BOOT0 跳线拨到 0**(从 Flash 启动),板子供电。

模板把烧录命令包成了 `make flash` 这个目标,在 `build/` 目录里直接跑:

```cmd
make flash
```

它展开就是一条 OpenOCD 命令,咱们看一眼它到底干了啥:

```cmd
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c "program STM32F1.bin verify reset exit 0x08000000"
```

`-f interface/stlink.cfg` 告诉 OpenOCD 用的是 ST-Link 调试器,`-f target/stm32f1x.cfg` 告诉它目标是 STM32F1 系列,`program ... verify reset exit 0x08000000` 是一连串动作:把 `STM32F1.bin` 写进 `0x08000000`(Flash 起始地址)、校验、复位、退出。烧录成功的标志是这几行:

```
Info : STLINK V2J14S0 (API v2) VID:PID 0483:3748
Info : Target voltage: 3.2V
** Programming Started **
** Programming Finished **
** Verify Started **
** Verified OK **
```

看到 `** Verified OK **`,固件就稳稳写进去了,板子会自动复位开始跑程序——PC13 那盏灯该开始一秒一闪了。需要完全擦除芯片时,模板还包了个 `make erase`,原理是 OpenOCD 的 `stm32f1x mass_erase`。

## 烧录失败,最常栽在哪几个坑上

烧录这步是新手事故高发区,笔者把最高频的几个坑连根因一起摆出来。

`Error: libusb_open() failed with LIBUSB_ERROR_NOT_FOUND` 或 `no device found`,根因是 Windows 没认出 ST-Link。回到 01 章那段:官方 ST-Link 装 STSW-LINK009 驱动,克隆版用 Zadig 换 WinUSB。设备管理器里 ST-Link 那项要是顶着黄色感叹号,就是驱动没到位。

`Error: target not halted` 或 `flash programming failed`,常见根因是芯片没在预期状态——BOOT0 跳线没拨到 0,或者 SWD 引脚被程序占用了。先检查 BOOT0,再试降低 SWD 时钟(OpenOCD 配置里加 `adapter speed 1000`)。

烧录命令报找不到 `STM32F1.bin`,多半是没在 `build/` 目录里跑 `make flash`——`make flash` 依赖当前目录下的 `.bin`,得 `cd build` 之后再跑。

还有个非技术的坑能让人怀疑人生:**USB 线是充电线不是数据线**。有些 Micro-USB 线只接了两根电源线,ST-Link 插上去压根没数据通路,换根能传数据的线立刻就好。

## 命令速查

| 干什么 | 命令 |
| --- | --- |
| 配置(Windows 带 -G) | `cmake -G "MinGW Makefiles" ..` |
| 编译 | `make` |
| 增量重编 | 改完源码直接 `make` |
| 完全重来 | 删掉 `build/` 重新配置编译 |
| 烧录 | `make flash` |
| 擦除 | `make erase` |
| 看 Flash/RAM 占用 | `arm-none-eabi-size --format=berkeley build/STM32F1.elf` |

---

[上一篇:代码走读](./03_code_walkthrough) | [下一篇:调试方法 →](./05_debugging)
