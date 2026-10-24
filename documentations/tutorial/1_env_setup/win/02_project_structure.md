---
title: 02 — 项目结构
---

# 02 — 项目结构

模板工程第一次打开，多半会犯怵：一个 `main.c`、一个 `system.c`、一长串 `CMakeLists.txt`、还有个吓人的 `.ld` 链接脚本，不知道哪个能改、哪个碰了就崩。笔者这一篇带咱们把这堆文件的分工理清楚——哪个是咱们写的应用代码、哪个是构建配置、哪个是芯片的内存地图。理解了结构，后面改起来才不慌。

代码本身（`main.c` 里点灯那段逻辑、`system.c` 里时钟怎么配）是[下一篇 03 · 代码走读](./03_code_walkthrough)的主场，咱们这里只看「谁是谁、各管什么」，不钻进代码行里去。

## 模板工程长什么样

模板在仓库的 `project/0_template/` 下，目录就这么几样东西：

```
project/0_template/
├── main.c                      # 咱们写的应用：点灯逻辑
├── system.c                    # 系统时钟配置
├── CMakeLists.txt              # 构建配置：怎么编译、链接
├── STM32F103C8TX_FLASH.ld      # 链接脚本：代码放芯片的哪块内存
├── stm32f1xx_hal_conf.h        # HAL 库的开关：启用哪些外设模块
├── .vscode/launch.json         # 调试器配置
└── build/                      # 编译产物（自动生成，别提交）
```

分一下类就清楚了：`main.c`、`system.c` 是咱们会动笔写的应用代码；`CMakeLists.txt`、`.ld`、`hal_conf.h` 这三个是「配置文件」，告诉工具链怎么编译、代码放哪、HAL 开哪些模块；`launch.json` 是给 VS Code 调试器用的；`build/` 是编译出来的东西，可以随时删掉重来。

## CMakeLists.txt：构建的中枢

`CMakeLists.txt` 是整个构建的中枢，笔者带咱们一段段读，重点看它**为什么**这么写，而不是死记语法。

开头几行先告诉 CMake「咱们在给一个没有操作系统的嵌入式目标编译」，所以 `CMAKE_SYSTEM_NAME` 设成 `Generic`、`CMAKE_SYSTEM_PROCESSOR` 设成 `ARM`，再把编译器指到交叉工具链那套 `arm-none-eabi-gcc`。这一段是交叉编译的「身份证」，少了它 CMake 会拿主机上的 GCC 去编，编出来的东西根本跑不进 ARM 芯片。

接着是编译选项，每一项都对应一个实打实的选择：`-mcpu=cortex-m3 -mthumb` 锁定咱们这颗 Cortex-M3 内核和它的 Thumb 指令集；`-O2` 是优化级别；`-DUSE_HAL_DRIVER -DSTM32F103xB` 两个宏，前者告诉 HAL 库「要用你」、后者告诉它「芯片是 F103 的小容量款」。这些宏漏一个，HAL 的行为就会跑偏。

然后是链接选项，里头 `-T STM32F103C8TX_FLASH.ld` 把代码交给链接脚本去摆位置，`-specs=nano.specs -specs=nosys.specs` 用精简版 C 库、关掉系统调用（嵌入式上没有操作系统给咱们 `printf` 兜底），`-Wl,--gc-sections` 把没用到的代码段垃圾回收掉——Blue Pill 只有 64 KB Flash，省一点是一点。

最后还有两个「自定义目标」值得单独点名，因为咱们后面会天天用：`make flash` 烧录、`make erase` 擦除。它们是靠 `add_custom_target` 包好的 OpenOCD 命令，具体的烧录操作放到[04 · 编译与烧录](./04_build_and_flash)里连同硬件一起讲。

## 链接脚本：代码在芯片里住哪儿

`.ld` 文件管的是程序的内存地图。Blue Pill 这颗芯片，Flash 在 `0x08000000`、有 64 KB，SRAM 在 `0x20000000`、有 20 KB——链接脚本最关键的就是把这两块地盘和它们的大小写对。`ENTRY(Reset_Handler)` 指定程序入口，栈顶 `_estack` 设在 SRAM 的末尾。

笔者在这篇里**故意不讲链接脚本的细节**——`.text`、`.data`、`.bss` 这几个段是怎么摆的、`.data` 为什么要在启动时从 Flash 搬到 SRAM、栈和堆的预算怎么算——这些都是 **P2 · 启动、链接、内存与时钟**（规划中）的主场。环境篇里咱们只要知道：有这么个文件，它把咱们的代码和芯片的物理内存对上了号，别手滑改坏它，就行。

## HAL 库从哪儿来：third_party 子模块

模板里用到的 HAL 库和 CMSIS 启动文件，不是仓库自己写的，是 ST 官方的 STM32CubeF1，以 git 子模块的形式放在 `third_party/STM32CubeF1/` 下。这就是为什么 [01 章装环境](./01_environment_setup)时非得跑一遍 `git submodule update --init --recursive`——子模块没拉下来，`stm32f1xx_hal.h` 就找不到，编译直接报 `No such file or directory`。

CMakeLists 里靠 `file(GLOB ...)` 把 HAL 驱动目录下所有 `.c` 收进来编译，再排掉带 `_template` 的模板文件。启动文件和 `system_stm32f1xx.c` 则从 CMSIS 的 Templates 目录里拿。这套做法让咱们不用手动一个个列源文件，代价是编进去的 HAL 模块多了点——想精简，就去 `stm32f1xx_hal_conf.h` 里把用不到的模块宏注释掉，Flash 立刻能省出一块。

## 编译产物：ELF、BIN、MAP 各是干什么的

跑完编译，`build/` 里会冒出三个核心产物，搞清它们的分工，调试和排错才有的放矢：

`STM32F1.elf` 带着完整的调试符号和段信息，是给 GDB 用的——咱们[05 章调试](./05_debugging)时，Cortex-Debug 加载的就是它。`STM32F1.bin` 是剥掉所有元数据的纯二进制，对应 Flash 里的原始数据，烧录烧的就是它。`STM32F1.map` 是链接器写的「内存体检报告」，记录每个符号、每个段落在哪个地址、占多大。

看程序占了多少 Flash 和 RAM，用 `arm-none-eabi-size`：

```cmd
arm-none-eabi-size --format=berkeley build/STM32F1.elf
```

```
   text    data     bss     dec     hex filename
   ...
```

这里 `text` 是代码（住 Flash），`data` 是有初值的全局变量（初值在 Flash、运行时搬到 RAM），`bss` 是没初值的全局变量（只在 RAM 清零）。所以 **Flash 占用 ≈ text + data，RAM 占用 ≈ data + bss**。Blue Pill 就 64 KB Flash、20 KB SRAM，这个数咱们得时不时回头看，尤其后面想塞更多模块的时候。段的具体含义同样是 P2 的主场，这里记住结论够用。

## 怎么基于模板开一个新工程

模板的意义就在于「复制、改两笔、就能起新工程」。最省事的做法是直接复制目录：

```bash
cp -r project/0_template project/my_project
cd project/my_project
rm -rf build
```

然后改两处:要是想换项目名,把 `CMakeLists.txt` 里 `project(STM32F1 ...)` 改成自己起的名字(生成的产物名会跟着变,`launch.json` 里的 `executable` 路径也得同步改);要加新源文件,比如 `uart.c`,就在 `add_executable` 的源文件列表里加上它。最后清掉 `build/` 重新配置编译:

```cmd
mkdir build && cd build
cmake -G "MinGW Makefiles" ..
make
```

换个芯片型号也是同理,但牵连面更大:链接脚本里的 Flash/RAM 大小、`CMakeLists.txt` 里的 `-DSTM32F103xB` 宏、启动文件 `startup_stm32f103xb.s`,这三处得配套改,缺一不可。

## 这一篇的坑

笔者把结构篇最容易踩的坑拢一下。编译报 `region 'FLASH' overflowed by XXXX bytes`,意思是代码塞爆了 64 KB Flash——回头去 `stm32f1xx_hal_conf.h` 把用不到的 HAL 模块注释掉,或者把优化级别换成更省空间的 `-Os`,通常能挤出一块。

`stm32f1xx_hal.h: No such file or directory`,根因永远是子模块没拉全,`git submodule update --init --recursive` 补上。

报 `undefined reference to 'main'`,要么是 `main.c` 里真没写 `main` 函数,要么是 `add_executable` 的源文件列表里漏加了 `main.c`。

---

[上一篇:环境配置](./01_environment_setup) | [下一篇:代码走读 →](./03_code_walkthrough)
