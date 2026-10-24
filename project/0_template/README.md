# 0_template · 全课程的黄金模板

这是 P0.4 约定的黄金模板:一个编译、烧录、调试全部跑通的最小 blink 工程。后续每个章节示例都从它复制起步,所以它的结构就是全课程的公共底座——复制过去的不只是 `main.c` 那点代码,还有交叉编译、链接、调试这套已经验证过的配置,新示例不用再从零搭一遍。

## 目录里有什么

```
project/0_template/
├── main.c                      # 应用入口:PC13 blink,复制后主要动笔的地方
├── firmware/                   # 公共底座,复制后基本不动
│   ├── system.c                # 时钟配置(HSI/2 × PLL16 = 64 MHz)与 SysTick
│   ├── stm32f1xx_hal_conf.h    # HAL 模块开关
│   └── STM32F103C8TX_FLASH.ld  # 链接脚本:Flash/SRAM 地址与段布局
├── tools/
│   └── check.sh                # 自检:工具链、依赖、从零编译
├── chmod_usb.sh                # WSL 路线放 ST-Link 权限用,原生 Linux 走 udev
├── CMakeLists.txt              # 构建配置,HAL 源从 ../../third_party/STM32CubeF1 取
└── .vscode/launch.json         # Cortex-Debug 配置(openocd + stlink)
```

HAL 库源码不在模板里,而在仓库级的 `third_party/STM32CubeF1`(git 子模块)。拿到仓库的第一件事是 `git submodule update --init`,少了它 CMake 会直接报找不到 `system_stm32f1xx.c`。

## 复制起步

新示例一律放在 `project/` 下,和模板平级,命名「两位编号_主题」,比如 `01_blink`、`02_uart_echo`:

```bash
cp -r project/0_template project/01_blink
rm -rf project/01_blink/build   # 旧产物别带走
```

复制完动笔的地方,按顺序就这几处:

1. 目录名改成 `NN_主题`。
2. `CMakeLists.txt` 里 `project(STM32F1 ...)` 改成示例自己的名字,产物名跟着它变——改了它就得同步改 `.vscode/launch.json` 里的 `executable`,不然 F5 会报找不到 `STM32F1.elf`(文件其实已经换了名)。
3. `main.c` 换成这个示例的业务逻辑。
4. 用到新外设时,去 `firmware/stm32f1xx_hal_conf.h` 把对应 HAL 模块的开关打开。

`firmware/` 里三样是底座,没有特别理由别动:时钟、链接脚本一改,前面章节验证过的行为就未必还成立。

## 自检、编译与烧录

```bash
./tools/check.sh                           # 自检:工具链、子模块、从零编译一次过
cmake -B build && cmake --build build      # 日常编译,出 build/STM32F1.elf 与 .bin
cmake --build build --target flash         # OpenOCD 烧录,需要 ST-Link
```

调试走 VS Code 的 Cortex-Debug,`launch.json` 已配好停在 `main`,按 F5 即可。

## 板卡资料

Blue Pill 的规格、引脚、接线在仓库的 [boards/STM32F103C8T6_BluePill](../../boards/STM32F103C8T6_BluePill/STM32F103C8T6_BluePill.md),SWD 四线(SWDIO、SWCLK、GND、3.3V)照那里的资料接。
