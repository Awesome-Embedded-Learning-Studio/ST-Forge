---
title: 01 — 环境配置（Windows 原生）
---

# 01 — 环境配置（Windows 原生）

装工具链这事儿，装桌面软件是「下一步、下一步、我同意」，装嵌入式工具链却像打一场小型战役——编译器版本不对，代码跑飞；驱动装错，下载器变砖；路径里有个空格，构建莫名其妙挂掉。笔者刚入坑那会儿，光是让「烧录」这步跑通就耗了一晚上。所以这一章咱们不急着写代码，先把刀磨利：把 ARM GCC、CMake、OpenOCD、Git、VS Code 这一整套装好、验过，后面编译烧录调试才不会反过来吃掉咱们的时间。

## 先把硬件备齐

软件开工之前，手边得有这几样东西，详细选购和真假识别放在[附录 · 硬件选项](./appendix_hardware)，这里只列最小集合：一块 Blue Pill（STM32F103C8T6）、一个 ST-Link V2 调试器（克隆版够用）、四根母对母杜邦线、一根能传数据的 Micro-USB 线。后面想看串口打印，再备一根几块钱的 USB-TTL 模块。

ST-Link 和 Blue Pill 的接线现在就记住，整条环境篇会反复用到——SWDIO 对 SWDIO、SWCLK 对 SWCLK、GND 对 GND，3.3V 那根只在板子没单独供电时才接。两路电源同时供电会倒灌，板子可能就这么废了，这个坑笔者放在这儿，等真接电源时咱们还会再提一次。

## 装 ARM GCC 交叉工具链

ARM GCC 是编译 STM32 代码的核心，`arm-none-eabi-gcc` 那一套，里头还自带 `make`，不用再单独装。

去 [ARM GNU Toolchain 下载页](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)，挑最新版的 Windows（mingw-w64）安装包，跑安装程序。安装路径笔者强烈建议改成不带空格的目录，比如 `C:\Tools\gcc-arm`——别图省事装进 `C:\Program Files\`，路径里的空格往后会在最想不到的地方让构建挂掉。安装时勾上「Add path to environment variable」，让它自己把 PATH 配好。

装完**另开一个**命令行窗口（PATH 改动对已经开着的窗口不生效），验证一下：

```cmd
arm-none-eabi-gcc --version
```

能打印出一行类似 `arm-none-eabi-gcc (Arm GNU Toolchain 13.2.Rel1 ...) 13.2.1` 的版本号，这把刀就算磨好了。

## 装 CMake

CMake 不直接编译，它负责生成给 `make` 用的构建文件。去 [CMake 官网下载页](https://cmake.org/download/) 拿 Windows x64 的 `.msi` 安装包，跑起来。安装时有一项**必须勾上**：「Add CMake to the system PATH for all users」——漏勾的话，后面命令行里 `cmake` 根本叫不出来。

```cmd
cmake --version
```

版本号得不低于 3.16（咱们工程的 `CMakeLists.txt` 最低就要求这个），低了就重新下个新的。

## 装 OpenOCD

OpenOCD 是烧录和调试的桥梁，靠它通过 ST-Link 把固件写进芯片。官方没给 Windows 预编译版，社区里用得最多的是 xPack 的版本：去 [xPack OpenOCD Releases](https://github.com/xpack-dev-tools/openocd-xpack/releases/) 下一份 `xpack-openocd-*-win32-x64.zip`，解压到 `C:\Tools\openocd`，确认里头有 `bin\openocd.exe`，再把 `C:\Tools\openocd\bin` 塞进系统 PATH。

```cmd
openocd --version
```

能打印出 `xPack Open On-Chip Debugger 0.12.0-...` 就行。xPack 版和官方 OpenOCD 功能完全一样，只是版本号多挂了个 xPack 后缀，不必纠结。

## 装 Git 和 VS Code

剩下两样是通用工具。Git 去 [Git for Windows](https://git-scm.com/) 装上，安装选项保持默认即可；VS Code 去[官网](https://code.visualstudio.com/)装上，安装时把「添加到 PATH」「注册为默认编辑器」这几项勾上，省得以后手动配。

```cmd
git --version
code --version
```

两条都能出版本号，就过关。

## 手动配 PATH（如果上面漏了）

要是哪个工具装的时候没勾「加进 PATH」，就得手动补。按 `Win + R` 输 `sysdm.cpl` 回车，「高级」→「环境变量」，在「系统变量」里找到 `Path` 编辑，把这几个目录新建进去：`C:\Tools\gcc-arm\bin`、`C:\Tools\openocd\bin`。

这里有个新手必踩的坑，根因就一句话：**PATH 的改动只对新开的窗口生效**。所以改完之后，把所有已经开着的命令行窗口、连同 VS Code，统统关掉重开，否则新窗口里能跑的命令，老窗口里还是「不是内部或外部命令」，能把人逼疯。重开之后用 `where arm-none-eabi-gcc`、`where openocd` 验一下，每条都能打印出完整路径，PATH 这关才算过。

## ST-Link 驱动：官方驱动和克隆版的 Zadig

ST-Link 插上电脑，Windows 还得认得它才行，这就得装驱动。

**官方 ST-Link** 走 ST 官方驱动就行：去 [STSW-LINK009](https://www.st.com/en/development-tools/stsw-link009.html) 下一份（可能要登录 ST 账号），解压后 64 位系统跑 `dpinst_amd64.exe`。装完插上 ST-Link，设备管理器的「通用串行总线设备」里能看到 `STMicroelectronics STLink dongle`，图标没黄色感叹号，就正常了。

**坑在克隆版这儿。** 咱们大多数人买的便宜 ST-Link V2 都是克隆版，它们用的 USB 芯片 VID/PID 跟官方不一样，STSW-LINK009 根本认不出来——这就是「设备管理器里一片黄色感叹号、OpenOCD 报 `LIBUSB_ERROR_NOT_FOUND`」的根因。解法是拿 [Zadig](https://zadig.akeo.ie/) 把驱动换成 WinUSB：Options → List All Devices，在下拉里找到 ST-Link 那项，驱动选 WinUSB，点 Replace Driver。

⚠️ 这个替换有代价，得提前知道:换完 WinUSB 之后,ST 官方那套工具(STM32CubeProgrammer 之类)就**认不出**这个 ST-Link 了,因为它们只认官方驱动。咱们走 OpenOCD 路线用 WinUSB 没问题,但哪天想切回官方工具,得用 Zadig 把驱动再换回去。两种驱动,两条路线,别混着用。

## VS Code 扩展和 Cortex-Debug

VS Code 装好之后，再装三个扩展：Cortex-Debug（`marus25.cortex-debug`，管 ARM 调试）、C/C++（`ms-vscode.cpptools`，管代码智能）、CMake Tools（`ms-vscode.cmake-tools`，管 CMake 集成）。命令行一把装最快：

```cmd
code --install-extension marus25.cortex-debug
code --install-extension ms-vscode.cpptools
code --install-extension ms-vscode.cmake-tools
```

Cortex-Debug 跑起来要找 `arm-none-eabi-gdb` 和 `openocd`。前面 PATH 配好的话，它自己就能找到，啥都不用再设。万一路径没生效（多半是 VS Code 没重开），就在 `settings.json` 里手动指一下：

```json
{
    "cortex-debug.armToolchainPath": "C:/Tools/gcc-arm/bin",
    "cortex-debug.openOCDPath": "C:/Tools/openocd/bin/openocd.exe"
}
```

JSON 里的路径**必须用正斜杠 `/` 或双反斜杠 `\\`**——单反斜杠在 JSON 里是转义符，写成 `C:\Tools\...` 会让路径解析直接废掉，这也是个高频坑。

## 一键体检：环境到底装好没有

工具多，一个一个验容易漏。笔者把体检命令拢一块，咱们挨个跑一遍：`arm-none-eabi-gcc --version`、`arm-none-eabi-gdb --version`、`cmake --version`、`make --version`、`openocd --version`、`git --version`，每条都该打印出版本号。`make` 这条特别提一下——它随 ARM GCC 一起来，不用单独装，`where make` 打印出的路径应该和 `arm-none-eabi-gcc` 在同一个 `bin` 下。

工具齐了，最后拿模板工程真编译一把，这才算把环境验穿。先把仓库拉下来、子模块初始化好（HAL 库在子模块里，漏了这步会报找不到头文件）：

```cmd
git clone <仓库地址> ST-Forge
cd ST-Forge
git submodule update --init --recursive
cd project\0_template
mkdir build && cd build
cmake -G "MinGW Makefiles" ..
make
```

这里有个 Windows 上**必须记住**的坑，根因是 CMake 在 Windows 上默认挑 Visual Studio 生成器：`cmake ..` 这步**一定要带 `-G "MinGW Makefiles"`**。省掉这个参数，CMake 就会生成 `.sln`、`.vcxproj` 那套 VS 工程文件，`make` 根本用不了，编译直接挂。本教程往后所有 `cmake` 命令，都默认带着这个 `-G`。

编译成功会看到末尾这几行，其中那行 `text data bss dec hex` 就是咱们程序占用的 Flash 和 RAM 体检表：

```
[100%] Built target STM32F1.elf
Generating STM32F1.bin
   text    data     bss     dec     hex filename
    ...      ...     ...     ...     ... STM32F1.elf
```

能走到这一步，ARM GCC、CMake、make、HAL 子模块全验穿了。烧录那一步要接硬件，咱们留到[04 · 编译与烧录](./04_build_and_flash)里连同 OpenOCD 一起正面对付。

## 这一套最容易绊倒咱们的几个坑

笔者把这一路最高频的几个坑拢在这，每个都带上「踩了会怎样」和「凭什么」——环境篇的坑，多半不是代码错，是工具没配到位。

`arm-none-eabi-gcc` 报「不是内部或外部命令」，根因就两个：要么工具没装进 `C:\Tools\gcc-arm\bin`，要么装了但 PATH 没配上，`where arm-none-eabi-gcc` 打印不出路径。照着上面的手动配 PATH 补上，**重开窗口**再试。

`cmake ..` 之后 build 目录里冒出 `.sln` 文件，就是漏了 `-G "MinGW Makefiles"`、CMake 跑去用 Visual Studio 生成器了。解法是删掉整个 build 目录重来，这次带上 `-G`——老缓存不删干净，新参数也未必生效。

烧录报 `LIBUSB_ERROR_NOT_FOUND` 找不到设备，回到上面克隆版 ST-Link 那段，多半是驱动没换成 WinUSB。

编译报 `stm32f1xx_hal.h: No such file or directory`，是子模块没拉下来，`git submodule update --init --recursive` 补上就好。

路径里带空格（比如项目放在 `C:\Users\My User\Documents\...`）导致莫名其妙的 `No such file or directory`，把项目挪到无空格路径，比如 `C:\Projects\ST-Forge`，一劳永逸。

## 命令速查

| 干什么 | 命令 |
| --- | --- |
| 验 ARM GCC | `arm-none-eabi-gcc --version` |
| 验 CMake | `cmake --version` |
| 验 make | `make --version` |
| 验 OpenOCD | `openocd --version` |
| 看工具在哪 | `where <命令名>` |
| 配工程（Windows 必带 -G） | `cmake -G "MinGW Makefiles" ..` |
| 编译 | `make` |

## 参考资料

- [ARM GNU Toolchain 下载](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
- [CMake 官方下载](https://cmake.org/download/)
- [xPack OpenOCD Releases](https://github.com/xpack-dev-tools/openocd-xpack/releases/)
- [Git for Windows](https://git-scm.com/) · [VS Code 官网](https://code.visualstudio.com/)
- [STSW-LINK009 驱动](https://www.st.com/en/development-tools/stsw-link009.html) · [Zadig](https://zadig.akeo.ie/)

---

[上一篇](../) · 本篇是 Windows 路径的第一篇 | [下一篇:项目结构 →](./02_project_structure)
