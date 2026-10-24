---
title: 01 — 环境配置（WSL · Linux）
---

# 01 — 环境配置（WSL · Linux）

走 Linux/WSL 这条路,工具链装起来比 Windows 省心得多——一条 `apt` 命令把编译器、构建工具、烧录器全拉下来,不用一个一个下安装包、不用配 PATH。但笔者得把丑话说在前头:WSL2 是个虚拟机,**它默认看不见插在 Windows 上的 USB 设备**,所以 ST-Link 得靠 `usbipd` 透传进来,这一步是 WSL 路线上最大的坑,也是本章的重头戏。原生 Linux(Ubuntu/Debian)没这麻烦,配个 udev 规则就完事。

## 先把硬件备齐

和 Windows 路径一样,手边得有:一块 Blue Pill(STM32F103C8T6)、一个 ST-Link V2 调试器、四根母对母杜邦线、一根能传数据的 Micro-USB 线,详细选购看[附录 · 硬件选项](./appendix_hardware)。ST-Link 接 Blue Pill 的接法记住:SWDIO 对 SWDIO、SWCLK 对 SWCLK、GND 对 GND,3.3V 只在板子没单独供电时才接——两路同时供电会倒灌烧板子。

## 一条命令装齐工具链

Ubuntu/Debian 下,工具链就是一条命令的事:

```bash
sudo apt update
sudo apt install -y gcc-arm-none-eabi cmake make openocd git build-essential
```

这一条把 ARM 交叉编译器(`arm-none-eabi-gcc`)、CMake、make、OpenOCD、git 全装上了。挨个验一遍版本号,能出版本就算过:

```bash
arm-none-eabi-gcc --version   # ARM 交叉编译器
cmake --version               # 需要 >= 3.16,Ubuntu 20.04+ 自带的就够
make --version
openocd --version
```

这里有个比 Windows 省心的地方:Linux 下这些工具装好就在 PATH 里,不用手动配、不用重开窗口、路径里也不会有空格——Windows 路线上那些 PATH 折腾,咱们这边基本不存在。

## VS Code:装在 Windows,用 Remote-WSL 连进来

WSL 路线有个反直觉的点:VS Code **装在 Windows 那边**,不是装在 WSL 里。然后在 Windows 的 VS Code 里装一个 **Remote-WSL** 扩展(`ms-vscode-remote.remote-wsl`),用它连进 WSL 的文件系统干活——代码在 Linux 侧,编辑器界面在 Windows 侧,两全其美。

```powershell
# 在 Windows PowerShell 里执行
code --install-extension ms-vscode-remote.remote-wsl
code --install-extension marus25.cortex-debug
code --install-extension ms-vscode.cpptools
code --install-extension ms-vscode.cmake-tools
```

调试用的 Cortex-Debug、C/C++、CMake Tools 三个扩展照装。之后在 WSL 终端里,进到项目目录敲 `code .`,VS Code 就会以 WSL 模式打开这个目录。

## USB 权限:Linux 原生走 udev 规则

Linux 默认不让普通用户直接访问 USB 设备,所以 ST-Link 插上,OpenOCD 多半会报权限不够。原生 Linux 的标准解法是写一条 udev 规则,让 ST-Link 这类设备对所有人可读写:

```bash
sudo tee /etc/udev/rules.d/49-stlinkv2.rules > /dev/null << 'EOF'
# ST-Link V2 / V2-1 / V3 常见型号
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE:="0666"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE:="0666"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374f", MODE:="0666"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3753", MODE:="0666"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger
```

规则生效后重新插拔一次 ST-Link,`lsusb | grep -i ST-LINK` 能看到设备,OpenOCD 也能访问了。这是「配一次,永久生效」的方案。临时方案是每次插拔后 `sudo chmod 666` 那个设备节点,但谁也不想每次都敲一遍。

## WSL2 的 USB 透传大坑

到这儿,原生 Linux 的朋友环境就齐了。WSL2 的朋友还得跨一道坎:**把 ST-Link 从 Windows 透传进 WSL**。根因是 WSL2 跑在一个轻量虚拟机里,默认看不到宿主机的 USB 设备,得靠 `usbipd-win` 这个工具手动转发。

先在 Windows 侧装 `usbipd-win`:

```powershell
# Windows PowerShell(管理员)
winget install --interactive --exact dorssel.usbipd-win
```

再在 WSL 里装好 USB 支持那套:

```bash
sudo apt install -y linux-tools-generic hwdata
sudo update-alternatives --install /usr/local/bin/usbip usbip /usr/lib/linux-tools/*-generic/usbip 20
```

然后是每次要用 ST-Link 时都得走一遍的动作:在 Windows 侧列出设备、把 ST-Link attach 到 WSL:

```powershell
# Windows PowerShell(管理员)
usbipd wsl list              # 列出所有 USB 设备,找到 ST-Link 的 BUSID,比如 1-2
usbipd wsl attach --busid 1-2
```

attach 之后,回到 WSL 里 `lsusb | grep -i ST-LINK` 才能看到它。最后还要设一下权限——模板里笔者留了个 `project/0_template/chmod_usb.sh` 脚本,跑一下就把 ST-Link 的设备节点权限放开:

```bash
cd /path/to/ST-Forge/project/0_template
./chmod_usb.sh
```

⚠️ 这个透传**不持久**:每次重新插拔 ST-Link、或者 WSL 重启,都得重新 `usbipd wsl attach` + `chmod_usb.sh`。这是 WSL2 路线最烦的地方,笔者不会粉饰它——嫌这一步折腾的,直接走 Windows 原生路径更省心。

## 一键体检:环境到底装好没有

挨个跑一遍,每条都该出版本号或识别到设备:`arm-none-eabi-gcc --version`、`cmake --version`、`make --version`、`openocd --version`、`lsusb | grep -i ST-LINK`(ST-Link 已 attach/插上的情况下)。

工具齐了,拿模板真编译一把验穿。拉仓库、初始化子模块(HAL 在子模块里,漏了报找不到头文件),进模板编译:

```bash
git clone <仓库地址> ST-Forge
cd ST-Forge
git submodule update --init --recursive
cd project/0_template
mkdir -p build && cd build
cmake ..
make
```

注意这里和 Windows 路线的一个区别:Linux 下 `cmake ..` **不用带 `-G "MinGW Makefiles"`**——Linux 默认就用 Unix Makefiles,直接能 `make`。Windows 那个必须带 `-G` 的坑,咱们这边不存在。

编译成功会看到末尾这几行,那行 `text data bss` 就是 Flash/RAM 占用:

```
[100%] Built target STM32F1.elf
Generating STM32F1.bin
   text    data     bss     dec     hex filename
   ...      ...     ...     ...     ... STM32F1.elf
```

走到这儿,工具链、CMake、HAL 子模块就全验穿了。烧录连同 OpenOCD 一起留到[04 · 编译与烧录](./04_build_and_flash)。

## 这一路最容易绊倒咱们的几个坑

`bash: arm-none-eabi-gcc: command not found`,根因是工具没装,`sudo apt install -y gcc-arm-none-eabi` 补上。装了还找不到,查 `echo $PATH` 里有没有 `/usr/bin`。

`Error: libusb_open() failed with LIBUSB_ERROR_ACCESS`,根因是 USB 权限没放开——原生 Linux 走上面的 udev 规则,WSL 走 `chmod_usb.sh`。这是 Linux 路线上最高频的坑。

WSL 里 `lsusb` 看不到 ST-Link,根因是没在 Windows 侧 `usbipd wsl attach`——记住 WSL2 看不见宿主 USB,必须先透传。

`cmake --version` 低于 3.16,老系统上偶发。用 Kitware 官方源、`pip install cmake` 或 `snap install cmake` 装个新版。

`stm32f1xx_hal.h: No such file or directory`,子模块没拉全,`git submodule update --init --recursive`。

## 命令速查

| 干什么 | 命令 |
| --- | --- |
| 装工具链(一次) | `sudo apt install -y gcc-arm-none-eabi cmake make openocd git build-essential` |
| 验编译器 | `arm-none-eabi-gcc --version` |
| 看 ST-Link 在不在 | `lsusb \| grep -i ST-LINK` |
| 配工程 | `cmake ..`(Linux 不用带 -G) |
| 编译 | `make` |

## 参考资料

- [ARM GCC 工具链](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
- [CMake 官方文档](https://cmake.org/documentation/) · [OpenOCD 文档](http://openocd.org/documentation/)
- [WSL 连接 USB 设备(微软官方)](https://learn.microsoft.com/zh-cn/windows/wsl/connect-usb) · [usbipd-win](https://github.com/dorssel/usbipd-win)

---

[上一篇](../) · 本篇是 WSL · Linux 路径的第一篇 | [下一篇:项目结构 →](./02_project_structure)
