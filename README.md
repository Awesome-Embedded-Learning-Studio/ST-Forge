# ST-Forge

ST-Forge 是一个面向 STM32 学习者的开源嵌入式开发工坊。项目第一阶段聚焦 STM32F103C8T6 Blue Pill，用 C、CMake、ARM GCC、OpenOCD、GDB 和 VS Code 搭建一条可复现、可调试、可长期扩展的学习路线。

这个仓库希望成为喜欢单片机的朋友们可以一起打磨的单片机学习：既有清晰的教程，也有能直接编译、烧录、调试的示例工程。

## 项目目标

- 从零搭建 STM32 开发环境，覆盖 Windows 与 WSL/Linux。
- 用 Blue Pill 跑通编译、烧录、调试、串口输出等基础闭环。
- 从 GPIO、时钟、中断、串口、定时器、DMA 逐步走向 I2C、SPI、CAN、USB、FATFS、RTOS。
- 把 `.claude` 中的 STM32 教材素材改造成更适合 GitHub 文档站和工程实践的教程。
- 让每个关键章节都有配套示例工程，而不只是文字说明。

## 技术主线

| 方向 | 选择 |
| --- | --- |
| 目标芯片 | STM32F103C8T6 |
| 目标板卡 | Blue Pill |
| 编程语言 | C |
| 构建系统 | CMake |
| 编译器 | ARM GCC |
| 烧录调试 | OpenOCD、GDB、ST-Link |
| 文档站 | VitePress |
| 驱动路线 | HAL 快速落地，关键章节补充寄存器视角 |

## 当前内容

- 文档首页：[documentations/index.md](documentations/index.md)
- 教程入口：[documentations/tutorial/index.md](documentations/tutorial/index.md)
- 总体规划：[documentations/planning/index.md](documentations/planning/index.md)
- 板卡资料：[boards/STM32F103C8T6_BluePill](boards/STM32F103C8T6_BluePill)

## 本地预览文档

```bash
pnpm install
pnpm run dev
```

默认开发服务器由 VitePress 启动，入口目录为 `site`。

## 近期路线

1. 完成仓库门面、规划页和教程骨架。
2. 新增 `examples/00_blink_cmake` 作为黄金模板。
3. 跑通 Blue Pill 的编译、烧录、调试闭环。
4. 扩展 GPIO、USART、EXTI、SysTick、定时器等基础章节。
5. 逐步加入 ADC、DMA、I2C、SPI、Flash、OLED、USB、RTOS 等进阶内容。

## 贡献方向

欢迎围绕以下方向参与：

- 验证教程步骤，补充不同系统下的排障记录。
- 修正文档错误、错别字、过期链接和不清晰表达。
- 提交可编译的 STM32 示例工程。
- 补充 Blue Pill 或其他 STM32 板卡适配资料。
- 提出适合初学者的小实验和综合项目。
