---
title: 🐧 WSL · Linux
---

# 🐧 WSL · Linux 路径

这条路径在 **WSL2(Windows Subsystem for Linux)** 里用 Linux 工具链开发 STM32F103C8T6:`gcc-arm-none-eabi`、`openocd`、`cmake`、`gdb` 全靠包管理器一条命令装好,体验更接近生产环境和 CI。

适合熟悉命令行、或想让开发环境和服务器/CI 保持一致的朋友。笔者得提前打个预防针:WSL2 下有个专属的大坑——调试器的 **USB 透传**,得靠 `usbipd` 把 Windows 侧的 ST-Link 转发给 WSL,这步搞不定,后面烧录调试全连不上。咱们在 [01 章](./01_environment_setup)里正面对付它。

👇 从头开始:[01 — 环境配置 →](./01_environment_setup)

> **侧边栏里两组长得很像的章节,是怎么回事?**
> 本教程按**开发平台**分了 🪟 Windows 原生 和 🐧 WSL · Linux 两条路径,章节结构一模一样,但每篇里的命令、驱动、USB 权限处理全是各管各的。**咱们按自己的系统选一条走完就行,两套都看没必要。** 不想折腾 WSL 的 USB 透传?那就去 [🪟 Windows 原生路径](../win/)。

完整索引见[环境配置总览](../)。
