---
title: 05 — 调试方法
---

# 05 — 调试方法

调试器是嵌入式开发者的上帝视角。不会用它,程序跑飞了只能拔电重来,瞪着漆黑的板子发呆;会用它,断点一打、寄存器一看,哪条指令崩的、变量当时是多少,无所遁形。这一章咱们把 Cortex-Debug 这个闭环跑通——从按 F5 启动,到断点、单步、看变量和寄存器。

HardFault 怎么从压栈的 PC 反推出故障指令、看门狗怎么用、半主机怎么走——这些都是后面章节的主场,环境篇只管把「能调试」这件事立起来。

## launch.json:调试器靠它找对文件

VS Code 调试靠 `.vscode/launch.json` 指挥,它告诉 Cortex-Debug 用哪个调试服务器、加载哪个 `.elf`、连哪种芯片。模板里的配置长这样:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "STM32 Debug",
            "type": "cortex-debug",
            "request": "launch",
            "servertype": "openocd",
            "cwd": "${workspaceRoot}",
            "executable": "build/STM32F1.elf",
            "configFiles": [
                "interface/stlink.cfg",
                "target/stm32f1x.cfg"
            ],
            "runToEntryPoint": "main",
            "svdFile": ""
        }
    ]
}
```

几个关键字段得看懂:`type: "cortex-debug"` 指定用 Cortex-Debug 扩展;`servertype: "openocd"` 让它在背后拉起 OpenOCD 当调试服务器;`executable` 指向编译出来的 `.elf`(注意,是带调试符号的那个,不是 `.bin`);`configFiles` 给 OpenOCD 喂 ST-Link 接口配置和 STM32F1 目标配置;`runToEntryPoint: "main"` 让程序一启动就跑到 `main` 停下,省得咱们自己翻到那。

这里笔者得诚实交代一笔:模板里 `executable` 这个值原本误写成了 `build/STM32Demo.elf`,而 CMake 实际生成的产物叫 `STM32F1.elf`(由 `CMakeLists.txt` 里的 `project(STM32F1 ...)` 决定),照原样调试会报找不到文件。笔者把它改成了正确的 `build/STM32F1.elf`,所以咱们现在看到的配置是对的。以后要是改了项目名,产物名跟着变,这个 `executable` 也得同步改——这是这俩字段绑死的根因。

Cortex-Debug 启动时要找 `arm-none-eabi-gdb` 和 `openocd`,01 章把 PATH 配好的话它自己就能找到;万一找不到,回 01 章看那段 `settings.json` 手动指路径的备用方案。

## 启动一次调试会话

前置条件就仨:工程已经编译( `build/STM32F1.elf` 存在)、ST-Link 接好、Blue Pill 供电且 BOOT0 在 0。然后在 VS Code 里按 `F5`(或者左侧「Run and Debug」面板点绿色播放键),选「STM32 Debug」配置。

启动时,Cortex-Debug 会先拉起 OpenOCD、让它通过 ST-Link 连上芯片,再把 `.elf` 加载进 GDB,最后让程序跑到 `main` 停下。看到底部状态栏出现「Cortex-Debug: Paused」、编辑器顶部出现调试工具栏,调试会话就算起来了。

## 断点和单步

断点是调试的看家本事。在代码编辑器里点行号左边的空白,出来一个红点,就是断点——程序执行到这儿会停下。设好后按 `F5` 继续,程序就会一路跑到下一个断点。

停下之后的几个动作,记住这几个键就够用:

| 动作 | 快捷键 | 干什么 |
| --- | --- | --- |
| 继续运行 | `F5` | 跑到下一个断点 |
| 单步跳过 | `F10` | 执行当前行,不进函数内部 |
| 单步进入 | `F11` | 钻进函数内部 |
| 单步返回 | `Shift+F11` | 跑完当前函数、回到调用处 |
| 重启 | `Ctrl+Shift+F5` | 重新启动调试会话 |
| 停止 | `Shift+F5` | 结束调试 |

`F10`(跳过)和 `F11`(进入)的区别是新手最先要分清的:遇到一个函数调用,`F10` 把它整个执行完停在下一行,`F11` 则钻进函数体里头一行行看。想看 HAL 库内部怎么跑,就用 `F11`;只想看自己的业务逻辑,就 `F10`。

断点还能加条件。右键断点选「Edit Breakpoint」,填个条件比如 `i == 100`,程序只有在 `i` 等于 100 那次循环才会停——找循环里特定轮次的 bug,这招比一遍遍 `F10` 省事得多。

## 看变量、看寄存器

程序停下之后,左边调试面板的几个区域是咱们的眼睛。「Variables」自动显示当前作用域里的局部变量,值会随单步实时更新。「Watch」可以手动添表达式,不光能看变量,还能看 `GPIOC->ODR` 这种外设寄存器,甚至 `*(uint32_t*)0x20000000` 这种直接按地址看内存。

「Call Stack」下面能展开「Registers」,看 Cortex-M3 的核心寄存器:`PC`(程序计数器,当前执行到哪)、`SP`(栈指针)、`LR`(链接寄存器,函数返回到哪)、`xPSR`(程序状态)。这几个寄存器在后面调 HardFault 的时候会反复用到——从压栈的 `PC` 能还原出故障指令,这是上帝视角的核心,留给后面的故障分析章节。

想看外设寄存器的名义分组(比如 GPIOC 的 CRL/CRH/IDR/ODR 各是多少),可以在 `launch.json` 里配 `svdFile` 指向一份 SVD 文件,调试时「Peripherals」面板就会按外设把寄存器归好类显示。模板里 `svdFile` 暂时空着,需要的时候再配。

## 调试启动失败,怎么查

调试启动不起来,按这个顺序排查,基本能覆盖九成情况。

先查硬件:ST-Link 的 SWDIO、SWCLK、GND 接对没,板子供电没,BOOT0 在不在 0。这一步查漏了,后面全白搭。

再查 OpenOCD 和驱动:命令行里手动跑一下 `openocd -f interface/stlink.cfg -f target/stm32f1x.cfg`,看它能不能连上芯片、打印出 `Info : STLINK V2J14S0 ...` 和 `Target voltage: 3.2V`。连不上、报 `LIBUSB_ERROR_NOT_FOUND`,回到 01 章那段——驱动没装或克隆版没换 WinUSB。

然后查 `.elf`: `build/STM32F1.elf` 存在不? `launch.json` 里的 `executable` 路径对不? 没编译就先 `make`,改过项目名就同步改 `executable`。

最后查扩展:Cortex-Debug 装了没、`arm-none-eabi-gdb` 在 PATH 里不(`arm-none-eabi-gdb --version` 能出版本号)。这些 01 章都验过,正常不会卡这儿。

断点不停、变量值「optimized out」,根因通常是编译优化把代码或变量优化掉了。调试阶段可以在 `CMakeLists.txt` 里临时把优化降到 `-O0 -g3`,优化一关,断点和变量就都老实了。这个优化和调试的张力,后面讲 `volatile` 的时候还会正面对一遍。

## 串口打印:另一双眼睛

除了断点,串口 `printf` 是嵌入式另一双常备的眼睛——程序跑着的时候持续往串口吐日志,不用停下也能看状态。不过它依赖 USART 这个外设,完整的串口用法和 `_write` 重定向留给 P3 讲,这里咱们只要知道:配好之后,Windows 上拿 PuTTY 或 Tera Term 连到 USB-TTL 对应的 COM 口、波特率 115200,就能看见 `printf` 的输出。在断点还不够、要看一段时间内状态变化的场景,串口比断点好使。

---

环境篇到这儿,编译、烧录、调试这三件套就齐了——咱们已经能把代码写进芯片、跑起来、还能在它跑的时候打断点看变量。下一篇咱们做个收尾,把环境篇涉及的几个概念拢一拢,然后指向后续课程。

[上一篇:编译与烧录](./04_build_and_flash) | [下一篇:STM32 基础速查 →](./06_stm32_basics)
