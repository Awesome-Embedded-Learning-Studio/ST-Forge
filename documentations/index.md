---
layout: home

hero:
  name: "ST-Forge"
  text: "STM32 裸机开发工坊"
  tagline: 面向 STM32F103C8T6 (Blue Pill)，从工具链搭建到调试的完整入门路径 · HAL + CMake
  actions:
    - theme: brand
      text: 开始学习
      link: /tutorial/
    - theme: alt
      text: 环境配置
      link: /tutorial/1_env_setup/win/01_environment_setup
    - theme: alt
      text: GitHub
      link: https://github.com/Awesome-Embedded-Learning-Studio/ST-Forge

features:
  - icon: 🚀
    title: 环境配置
    details: 从零搭建 STM32 开发环境，ARM GCC 工具链安装、VSCode + Cortex-Debug 配置一应俱全。
    link: /tutorial/1_env_setup/win/01_environment_setup
  - icon: 📁
    title: 项目结构
    details: 解析模板项目的目录组织与 CMake 构建系统，理解工程是怎么跑起来的。
    link: /tutorial/1_env_setup/win/02_project_structure
  - icon: 💻
    title: 代码详解
    details: 逐行讲解 main.c、system.c 与 HAL 配置，从启动到第一行业务逻辑。
    link: /tutorial/1_env_setup/win/03_code_walkthrough
  - icon: 🔧
    title: 编译与烧录
    details: CMake 构建 .elf，使用 OpenOCD / ST-Link 把固件烧录进 Blue Pill。
    link: /tutorial/1_env_setup/win/04_build_and_flash
  - icon: 🐛
    title: 调试方法
    details: 使用 GDB + OpenOCD + J-Link/ST-Link 进行断点、单步与寄存器查看。
    link: /tutorial/1_env_setup/win/05_debugging
  - icon: 📚
    title: STM32 基础概念
    details: Cortex-M3 架构、存储器映射、时钟树与外设基础，打好理论地基。
    link: /tutorial/1_env_setup/win/06_stm32_basics
  - icon: 🔌
    title: 硬件选项
    details: Blue Pill 开发板、调试器与扩展模块的选型指南，附录供参考。
    link: /tutorial/1_env_setup/win/appendix_hardware
---
