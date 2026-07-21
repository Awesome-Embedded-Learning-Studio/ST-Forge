---
title: ST-Forge 行动路线图
---

# ST-Forge 行动路线图

这份路线图把[总体规划](./)展开成具体、可勾选的行动项。每一项都写成“下一步就能动手”的粒度，按里程碑分组。状态约定：

- `[x]` 已完成　`[~]` 进行中 / 已有半成品　`[ ]` 待办

工程与文档命名约定（贯穿全文）：

- 教程目录用 `NN_descriptive_name`（如 `0_env_setup`）。
- 示例工程目录用 `examples/NN_descriptive_name`，编号与所属教程章节对齐。
- 每篇正式教程遵循统一的八段式结构（见[总体规划 · 文档写作标准](./#文档写作标准)）。

---

## M1 · 基础篇骨架

目标：站点结构、板卡资料、章节模板都到位，让后续每一章都能“照着填”。

### 1.1 站点结构与导航

- [ ] 把 `documentations/tutorial/` 改造成五线结构：`0_basics`（基础篇）/ `1_peripherals`（外设篇）/ `2_projects`（实战篇）/ `3_troubleshooting`（排障篇）/ `4_templates`（模板篇）。
- [ ] 保留 `0_env_setup` 作为基础篇前置，或并入 `0_basics` 的环境章节，避免两套编号打架。
- [ ] 统一首页、教程首页、规划页的技术表述：统一写“STM32F103C8T6 (Blue Pill) · HAL · CMake · ARM GCC · OpenOCD · GDB”。
- [ ] 首页 hero 的“环境配置”按钮区分 Windows / WSL 两个入口（当前只指向 win）。
- [ ] 教程首页补一张“从零到跑通”的学习路径图，标注每一步对应章节。

### 1.2 板卡资料

- [~] 完善 `boards/STM32F103C8T6_BluePill/STM32F103C8T6_BluePill.md`：补全引脚图、供电方式、BOOT0/BOOT1 启动模式、SWD 调试接线、晶振与复位电路。
- [ ] 新增 `boards/STM32F103C8T6_BluePill/hardware_bom.md`：Blue Pill、ST-Link V2、USB-TTL、杜邦线、面包板的型号与采购清单。
- [ ] 新增“常见假板 / CS32 / 克隆芯片识别与风险”小节，告诉学习者如何判断板子和调试器是否正常。
- [ ] 在 `board_defconfig` 中固化芯片型号、Flash/RAM 大小、链接地址，供示例工程复用。

### 1.3 章节模板与规范

- [ ] 新建 `documentations/tutorial/_templates/chapter_template.md`，落地八段式结构（目标 / 硬件准备 / 概念解释 / 工程改动 / 编译烧录 / 现象验证 / 常见问题 / 延伸练习）。
- [ ] 在 `_templates/` 增加 `example_readme_template.md`，规定每个示例工程 README 必含：接线、构建命令、烧录命令、预期现象。
- [ ] 在规划页补充“示例工程命名规则”说明（`NN_` 前缀 + 下划线小写），写进贡献指南。
- [ ] 把这套约定同步到 `README.md` 的贡献方向。

### M1 完成标准

- 站点五线骨架可见，侧边栏层级正确。
- Blue Pill 板卡页能回答“买什么、怎么接、怎么判断板子正常”。
- 任何人新写一章，都能照模板填，不用重新发明结构。

---

## M2 · 黄金模板

目标：`examples/00_blink_cmake` 成为后续所有章节的复制起点，跑通“编译 → 烧录 → 调试”闭环。

### 2.1 公共底座 firmware/

- [ ] 新建 `firmware/` 目录，集中放置公共启动文件、链接脚本、HAL/CMSIS 封装，避免每个示例重复散落。
- [ ] 确定 HAL 引入方式（子模块 / vendor 包 / 本地拷贝），写进 `firmware/README.md`。
- [ ] 提供统一链接脚本（`STM32F103C8TX_FLASH.ld`）与启动文件（`startup_stm32f103xb.s`）。
- [ ] 提供 `system_stm32f1xx.c` / `HAL_Config` 等公共配置。

### 2.2 黄金模板 examples/00_blink_cmake

- [ ] 新建 `examples/00_blink_cmake`，包含：`CMakeLists.txt`、`main.c`（HAL 点亮板载 LED）、`.gitignore`、`README.md`。
- [ ] CMake 工程能引用 `firmware/` 公共底座，不复制启动文件。
- [ ] 提供构建脚本：`cmake -B build` + `cmake --build build` 产出 `.elf/.bin/.hex`。
- [ ] 提供 OpenOCD 配置（`openocd.cfg` 或 `.cfg` 片段）和一键烧录命令。
- [ ] 提供 `.vscode/launch.json` + `tasks.json`，Cortex-Debug 能断点、单步、看寄存器。
- [ ] README 写清 Win 与 WSL 两条路径各自的命令差异（尤其 WSL 下 USB/udev 权限）。

### 2.3 工具脚本 tools/

- [ ] 新建 `tools/`，放构建 / 烧录 / 校验辅助脚本（如 `flash.sh`、`check_env.sh`）。
- [ ] `check_env.sh` 能检测 arm-none-eabi-gcc、cmake、openocd、gdb 是否就位并给出缺失提示。
- [ ] 脚本同时兼容 Windows（PowerShell / Git Bash）与 WSL/Linux（bash）。

### M2 完成标准

- `git clone` 后照 README，能在 Windows 和 WSL 两端各跑通一次“点灯 + 断点调试”。
- 任何人复制 `00_blink_cmake` 改个外设，就能起新示例工程。

---

## M3 · 基础篇核心章节

目标：从“能点灯”走到“能写小型交互程序”。每章 = 一篇八段式文档 + 一个可编译示例工程。已有环境篇（`0_env_setup` win/wsl 双版本）覆盖了路线图中 0.2–0.6 的内容，下面只列剩余与芯片基础部分。

### 3.1 芯片与工程基本功（对应规划 1.x）

- [ ] 1.1 Cortex-M3 与 STM32F103 内存映射：手算 GPIO 寄存器地址 → 文档。
- [ ] 1.2 启动文件、链接脚本与 map 文件：看懂 Flash/RAM 占用 → 文档。
- [ ] 1.3 CMake 工程结构：以黄金模板为例拆解 → 文档（可复用 `02_project_structure` 内容升级）。
- [ ] 1.4 C 语言硬件基础：位操作、宏、结构体、指针、`volatile` → 文档 + `examples/10_c_for_hardware` 小演示。
- [ ] 1.5 HAL 与寄存器的关系：用 GPIO 对照 HAL 调用与寄存器变化 → 文档。
- [ ] 1.6 时钟树：HSI/HSE/PLL 与 72 MHz 配置 → 文档。
- [ ] 1.7 map 文件与内存占用：从构建产物反推代码进入芯片的方式 → 文档。

### 3.2 最小外设能力（对应规划 2.x，每章配示例工程）

- [ ] 2.1 GPIO 输出 → `examples/01_gpio_output`（板载 LED 闪烁）。
- [ ] 2.2 GPIO 输入 → `examples/02_gpio_input`（按键、上拉下拉、软件消抖）。
- [ ] 2.3 SysTick 与 delay → `examples/03_systick_delay`（µs/ms 延时、阻塞代价）。
- [ ] 2.4 USART 输出 → `examples/04_usart_output`（`printf`、串口工具、乱码排查）。
- [ ] 2.5 USART 输入 → `examples/05_usart_input`（回环、简单命令解析）。
- [ ] 2.6 EXTI 外部中断 → `examples/06_exti_button`（按键中断、NVIC、优先级）。
- [ ] 2.7 基本定时器 → `examples/07_basic_timer`（周期中断、非阻塞闪烁）。
- [ ] 2.8 PWM 入门 → `examples/08_pwm_breathing`（呼吸灯、占空比调节）。
- [ ] 2.9 调试与故障分析 → `examples/09_debug_hardfault`（断点、单步、HardFault、看门狗式排查思路）。

### 3.3 每章质量门槛

- [ ] 每章都能 `cmake --build` 通过。
- [ ] 每章 README 写明预期串口输出 / LED 状态 / 测量结果。
- [ ] 每章“常见问题”至少收录 3 条真实排障（烧录失败、串口乱码、HardFault 等）。

### M3 完成标准

- GPIO、输入、SysTick、USART、EXTI、定时器、PWM 七项各有文档 + 示例。
- 学习者按序做完，能独立写出非阻塞的串口交互程序。

---

## M4 · 基础篇收官项目 Blue Pill Mini Console

目标：不依赖额外模块，把基础篇能力串成一个完整小设备。

- [ ] 新建 `examples/99_bluepill_mini_console`。
- [ ] 实现串口命令 `led on/off/toggle`（USART + 命令解析 + GPIO 输出）。
- [ ] 实现串口命令 `blink 100/500/1000`（定时器 + 状态机 + 非阻塞逻辑）。
- [ ] 实现串口命令 `pwm 0-100`（PWM + 参数解析 + 占空比）。
- [ ] 实现按键切换运行状态（GPIO 输入 + 消抖 + EXTI）。
- [ ] 实现结构化状态打印（`printf` + 状态输出）。
- [ ] 配套调试章节：用断点 / watch / 寄存器观察理解项目运行。
- [ ] 写一篇项目教程，按“需求 → 设计 → 实现 → 调试 → 扩展”组织。
- [ ] 产出命令清单 + 预期串口输出 + 常见问题排障表。
- [ ] README 增加基础篇完成后的学习成果说明。

### M4 完成标准

- 学习者照着做，能拿出一个可演示、可调试、可扩展的串口控制小设备。

---

## M5 · 实战篇首批项目选择

目标：从远期项目地图里挑出首批项目，准备零件库与贡献流程。

- [ ] 从候选（OLED 小仪表盘 / 桌面环境监测站 / 迷你数据记录仪）中确定 2–3 个首批项目。
- [ ] 为首批项目建外设模块购买清单 + 引脚占用表。
- [ ] 每个项目写一份需求草案：核心看点、依赖知识、硬件成本、简化版本。
- [ ] 整理 `CONTRIBUTING.md` 贡献指南，区分文档 / 示例 / 板卡三类贡献路径。
- [ ] 新增 Issue 模板（环境问题 / 教程错误 / 板卡适配 / 功能建议）。
- [ ] 梳理 Good First Issue（错别字、截图补充、模块验证、排障条目）。

### M5 完成标准

- 有明确的“下一个实战项目”和它的零件清单。
- 贡献者能找到清晰的参与入口。

---

## 持续维护 · 排障篇 / 模板篇 / 社区

不绑定里程碑，随真实学习和 issue 持续沉淀。

- [ ] 排障篇：从每章“常见问题”抽取，按现象（烧录失败 / 串口乱码 / HardFault / 时钟异常）建索引页。
- [ ] 模板篇：把黄金模板与章节模板沉淀成可复用模板说明，服务社区贡献。
- [ ] 展示材料：每个明星实验保留图片 / GIF / 串口日志，方便 README 展示。
- [ ] 版本路线标签：`v0.1` 跑通环境、`v0.2` 基础外设、`v0.3` 总线模块、`v1.0` 完整课程。
- [ ] 定期回看本文档，勾选完成项、更新“下一步”。

---

## 当前最该动手的三件事

1. **M2 · 黄金模板**：新建 `examples/00_blink_cmake` + `firmware/` 公共底座，跑通 Win 与 WSL 的编译烧录调试闭环。
2. **M1 · 章节模板**：落地八段式 `chapter_template.md`，后续所有章节照此扩写。
3. **M1 · 板卡资料**：补全 Blue Pill 引脚 / 供电 / 启动模式 / ST-Link 接线，作为所有硬件章节的基准参考。
