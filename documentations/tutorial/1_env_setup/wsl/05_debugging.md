---
title: 05 — 调试方法（WSL · Linux）
---

# 05 — 调试方法（WSL · Linux）

调试器是嵌入式开发者的上帝视角。不会用它,程序跑飞了只能拔电重来,瞪着漆黑的板子发呆;会用它,断点一打、寄存器一看,哪条指令崩的、变量当时多少,无所遁形。这一章咱们把 Cortex-Debug 这个闭环跑通。HardFault 怎么从压栈的 PC 反推故障指令、看门狗、半主机——这些留给后面,环境篇只管把「能调试」立起来。

## 调试之前:WSL 得先看到 ST-Link

WSL 路线有个前置动作笔者得先强调:Cortex-Debug 背后跑的 OpenOCD,得能访问 ST-Link 才行。可 WSL2 默认看不见宿主 USB,所以**每次调试前**都得像[04 章烧录](./04_build_and_flash)那样,先在 Windows 侧把 ST-Link attach 进来,再放开权限:

```powershell
# Windows PowerShell(管理员)
usbipd wsl list
usbipd wsl attach --busid <BUSID>
```

```bash
# WSL 里
cd /path/to/ST-Forge/project/0_template && ./chmod_usb.sh
lsusb | grep -i ST-LINK   # 确认能看到
```

这一步漏了,后面 Cortex-Debug 启动时 OpenOCD 会报找不到设备。原生 Linux 的朋友配过 udev 规则就免了这步。

## launch.json:调试器靠它找对文件

VS Code 调试靠 `.vscode/launch.json` 指挥。模板里的配置长这样:

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

`type: "cortex-debug"` 指定扩展,`servertype: "openocd"` 让它背后拉起 OpenOCD,`executable` 指向带调试符号的 `.elf`(不是 `.bin`),`configFiles` 喂 ST-Link 接口和 STM32F1 目标配置,`runToEntryPoint: "main"` 让程序启动就跑到 `main` 停下。

这里笔者诚实交代一笔:模板里 `executable` 原本误写成 `build/STM32Demo.elf`,而 CMake 实际生成的叫 `STM32F1.elf`(由 `project(STM32F1 ...)` 决定),照原样调试会找不到文件。笔者改成了正确的 `build/STM32F1.elf`。以后改项目名,产物名跟着变,这个 `executable` 也得同步改。

Cortex-Debug 要找 `arm-none-eabi-gdb` 和 `openocd`,apt 装好的话 PATH 里有,它自己能找到。

## 启动一次调试会话

前置齐了:工程编译过(`build/STM32F1.elf` 存在)、ST-Link 接好并已 attach/放权限、BOOT0 在 0。VS Code 里按 `F5` 或左侧「Run and Debug」面板点播放键,选「STM32 Debug」。Cortex-Debug 拉起 OpenOCD 连芯片、加载 `.elf` 进 GDB、跑到 `main` 停下。看到底部「Cortex-Debug: Paused」和顶部调试工具栏,会话就起来了。

## 断点和单步

点行号左边空白出来红点就是断点,程序执行到这儿停下。几个动作记住这几个键:

| 动作 | 快捷键 | 干什么 |
| --- | --- | --- |
| 继续运行 | `F5` | 跑到下一个断点 |
| 单步跳过 | `F10` | 执行当前行,不进函数 |
| 单步进入 | `F11` | 钻进函数内部 |
| 单步返回 | `Shift+F11` | 跑完当前函数回到调用处 |
| 重启 | `Ctrl+Shift+F5` | 重启调试会话 |
| 停止 | `Shift+F5` | 结束调试 |

`F10`(跳过)和 `F11`(进入)要分清:遇函数调用,`F10` 整个执行完停在下一行,`F11` 钻进函数体。看 HAL 内部用 `F11`,看自己逻辑用 `F10`。断点还能加条件(右键「Edit Breakpoint」,填 `i == 100`),找循环特定轮次的 bug 比一遍遍 `F10` 省事。

## 看变量、看寄存器

程序停下后,左边面板是咱们的眼睛。「Variables」自动显示局部变量,值随单步实时更新。「Watch」能手动添表达式,看 `GPIOC->ODR` 这种外设寄存器、甚至 `*(uint32_t*)0x20000000` 按地址看内存。「Call Stack」下展开「Registers」,看 `PC`/`SP`/`LR`/`xPSR` 这些核心寄存器——后面调 HardFault 会反复用它们从压栈的 PC 还原故障指令,留给后面的故障分析。

想看外设寄存器分组,可以在 `launch.json` 配 `svdFile` 指向一份 SVD 文件,调试时「Peripherals」面板按外设归类显示。

## 调试启动失败,怎么查

按这个顺序排查,覆盖九成情况。

先查 WSL 这步:ST-Link attach 了没、`chmod_usb.sh` 跑了没、`lsusb` 能看到没。这一步漏了,后面全白搭。原生 Linux 则查 udev 规则生效没。

再查 OpenOCD 连接:命令行手动 `openocd -f interface/stlink.cfg -f target/stm32f1x.cfg`,看能不能连上、打印出 `Info : STLINK V2J14S0 ...`。连不上、报 `LIBUSB_ERROR_ACCESS`,是权限没放开。

然后查 `.elf`:`build/STM32F1.elf` 存在不、`launch.json` 的 `executable` 路径对不。没编译先 `make`。

最后查扩展:Cortex-Debug 装了没、`arm-none-eabi-gdb` 在 PATH 不(`arm-none-eabi-gdb --version`)。

断点不停、变量「optimized out」,根因通常是编译优化把代码变量优化掉了。调试阶段可在 `CMakeLists.txt` 临时降到 `-O0 -g3`。这个优化和调试的张力,后面讲 `volatile` 时正面对一遍。

## 串口打印:另一双眼睛

除了断点,串口 `printf` 是另一双常备眼睛——程序跑着时持续吐日志,不用停下也能看状态。不过它依赖 USART 外设,完整用法留给 P3。这里只要知道:配好后,Linux 下用 `minicom` 或 `screen` 连到 USB-TTL 对应的串口设备(`/dev/ttyUSB0` 之类)、波特率 115200,就能看见输出。看一段时间内状态变化的场景,串口比断点好使。

---

环境篇到这儿,编译、烧录、调试三件套齐了。下一篇做个收尾,把概念拢一拢、指向后续课程。

[上一篇:编译与烧录](./04_build_and_flash) | [下一篇:STM32 基础速查 →](./06_stm32_basics)
