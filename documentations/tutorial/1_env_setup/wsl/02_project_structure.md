---
title: 02 — 项目结构（WSL · Linux）
---

# 02 — 项目结构（WSL · Linux）

模板工程第一次打开多半犯怵:一个 `main.c`、一个 `system.c`、一长串 `CMakeLists.txt`、还有个吓人的 `.ld` 链接脚本,不知道哪个能改、哪个碰了就崩。笔者这篇带咱们把分工理清——哪个是应用代码、哪个是构建配置、哪个是芯片的内存地图。理解了结构,后面改起来才不慌。

代码本身(`main.c` 点灯逻辑、`system.c` 时钟怎么配)是[下一篇 03 · 代码走读](./03_code_walkthrough)的主场,咱们这里只看「谁是谁、各管什么」。

## 模板工程长什么样

模板在 `project/0_template/` 下:

```
project/0_template/
├── main.c                      # 咱们写的应用:点灯逻辑
├── system.c                    # 系统时钟配置
├── CMakeLists.txt              # 构建配置
├── STM32F103C8TX_FLASH.ld      # 链接脚本:代码放芯片哪块内存
├── stm32f1xx_hal_conf.h        # HAL 库开关
├── .vscode/launch.json         # 调试器配置
├── chmod_usb.sh                # WSL 下放开 ST-Link USB 权限的小脚本
└── build/                      # 编译产物(自动生成,别提交)
```

分一下类:`main.c`、`system.c` 是咱们会动笔写的应用代码;`CMakeLists.txt`、`.ld`、`hal_conf.h` 是配置文件;`launch.json` 给调试器;`chmod_usb.sh` 是 WSL 路线专属的小帮手([04 章](./04_build_and_flash)会用到);`build/` 是编译产物,随时能删。

## CMakeLists.txt:构建的中枢

`CMakeLists.txt` 是构建中枢,笔者带咱们看它**为什么**这么写。

开头告诉 CMake「在给一个没有操作系统的嵌入式目标编译」:`CMAKE_SYSTEM_NAME` 设 `Generic`、`CMAKE_SYSTEM_PROCESSOR` 设 `ARM`,编译器指到 `arm-none-eabi-gcc`。这一段是交叉编译的「身份证」,少了它 CMake 会拿主机 GCC 去编,编出来的东西跑不进 ARM。

编译选项每一项都是实打实的选择:`-mcpu=cortex-m3 -mthumb` 锁定 Cortex-M3 内核和 Thumb 指令集;`-O2` 优化级别;`-DUSE_HAL_DRIVER -DSTM32F103xB` 两个宏,一个告诉 HAL「要用你」、一个告诉它「芯片是 F103 小容量款」。

链接选项里 `-T STM32F103C8TX_FLASH.ld` 把代码交给链接脚本摆位置,`-specs=nano.specs -specs=nosys.specs` 用精简 C 库、关掉系统调用,`-Wl,--gc-sections` 垃圾回收没用的代码段——Blue Pill 只有 64 KB Flash,省一点是一点。

末尾两个自定义目标咱们后面天天用:`make flash` 烧录、`make erase` 擦除。具体操作放到[04 · 编译与烧录](./04_build_and_flash)。

## 链接脚本:代码在芯片里住哪儿

`.ld` 文件管程序的内存地图。Blue Pill 的 Flash 在 `0x08000000`、64 KB,SRAM 在 `0x20000000`、20 KB——链接脚本最关键的就是把这两块地盘写对。`ENTRY(Reset_Handler)` 指定入口,栈顶 `_estack` 设在 SRAM 末尾。

`.text`、`.data`、`.bss` 怎么摆、`.data` 为什么启动时要从 Flash 搬到 SRAM、栈堆预算怎么算——这些都是 **P2 · 启动、链接、内存与时钟**(规划中)的主场。环境篇里咱们只要知道:有这么个文件,把代码和芯片物理内存对上了号,别手滑改坏它。

## HAL 库从哪儿来:third_party 子模块

HAL 库和 CMSIS 启动文件是 ST 官方的 STM32CubeF1,以 git 子模块形式放在 `third_party/STM32CubeF1/`。这就是为什么装环境时非得 `git submodule update --init --recursive`——子模块没拉下来,`stm32f1xx_hal.h` 就找不到。CMakeLists 里靠 `file(GLOB ...)` 收 HAL 的 `.c` 编译。想精简 Flash,就去 `stm32f1xx_hal_conf.h` 把用不到的模块宏注释掉。

## 编译产物:ELF、BIN、MAP

`build/` 里三个核心产物:`STM32F1.elf` 带调试符号,给 GDB 用;`STM32F1.bin` 是纯二进制,烧录用;`STM32F1.map` 是内存体检报告。看占用用 `arm-none-eabi-size`:

```bash
arm-none-eabi-size --format=berkeley build/STM32F1.elf
```

`text` 进 Flash,`data`/`bss` 进 RAM,所以 **Flash ≈ text + data,RAM ≈ data + bss**。Blue Pill 就 64 KB Flash、20 KB SRAM,这数得时不时回头看。段的含义留给 P2。

## 怎么基于模板开新工程

模板的意义就是「复制、改两笔、起新工程」:

```bash
cp -r project/0_template project/my_project
cd project/my_project
rm -rf build
mkdir -p build && cd build
cmake ..
make
```

想换项目名,改 `CMakeLists.txt` 里 `project(STM32F1 ...)`,产物名和 `launch.json` 的 `executable` 路径跟着同步;加新源文件,往 `add_executable` 的列表里加。换芯片型号则牵连三处:链接脚本的 Flash/RAM 大小、`-DSTM32F103xB` 宏、启动文件 `startup_stm32f103xb.s`,配套改。

## 这一篇的坑

`region 'FLASH' overflowed` 是代码塞爆了 64 KB,去 `hal_conf.h` 关掉用不到的模块,或换 `-Os` 优化大小。

`stm32f1xx_hal.h: No such file or directory` 永远是子模块没拉全,`git submodule update --init --recursive` 补上。

`undefined reference to 'main'`,要么没写 `main`,要么 `add_executable` 漏加了 `main.c`。

---

[上一篇:环境配置](./01_environment_setup) | [下一篇:代码走读 →](./03_code_walkthrough)
