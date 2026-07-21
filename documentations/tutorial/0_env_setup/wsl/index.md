---
title: 🐧 WSL · Linux
---

# 🐧 WSL · Linux 路径

这条路径在 **WSL2（Windows Subsystem for Linux）** 中使用 Linux 工具链开发 STM32F103C8T6：`gcc-arm-none-eabi`、`openocd`、`cmake`、`gdb` 全部通过包管理器安装，体验更接近生产环境与 CI。

适合**熟悉命令行**、或希望开发环境与服务器 / CI 一致的同学。需要注意的是 WSL2 下调试器的 USB 穿透（`usbipd` / `udev` 权限）。

👇 从第一章开始：[01 - 环境配置 →](./01_environment_setup)

> **为什么侧边栏里有两组长得很像的章节？**
> 本教程按**开发平台**分为 🪟 Windows 原生 与 🐧 WSL · Linux 两条路径，章节结构一致，但每篇内容都针对各自平台（工具链、驱动、USB 权限、命令都不同）。**按你的系统选一条路径走完即可，不需要两套都看。** 不想折腾 WSL？前往 [🪟 Windows 原生路径](../win/)。

完整章节索引见 [环境配置总览](../)。
