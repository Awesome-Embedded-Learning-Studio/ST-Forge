---
title: 03 — 代码走读（WSL · Linux）
---

# 03 — 代码走读（WSL · Linux）

模板的 `main.c` 短得吓人,满打满算也就二十来行,可它把 HAL 裸机程序的整套套路全包进去了——初始化库、配时钟、配外设、进死循环干活。笔者带咱们从头读到尾,套路一通,以后看任何 HAL 程序都不怵。

丑话说在前头:这篇只够咱们「看懂模板跑起来」,真要讲透每一处——GPIO 八种模式、完整时钟树、`HAL_Delay` 为什么阻塞——那是后面 **P2(时钟)**、**P3(GPIO、中断)** 的活,笔者会在该收的地方标注「留给后面」,不在环境篇铺开。

## main.c 的骨架

先把整个 `main` 拎出来看骨架:

```c
int main() {
  HAL_Init();
  SystemClock_Config();

  GPIO_InitTypeDef def;
  def.Mode = GPIO_MODE_OUTPUT_PP;
  def.Pin = GPIO_PIN_13;
  def.Speed = GPIO_SPEED_FREQ_LOW;
  def.Pull = GPIO_PULLDOWN;
  __HAL_RCC_GPIOC_CLK_ENABLE();
  HAL_GPIO_Init(GPIOC, &def);

  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, GPIO_PIN_SET);

  while (1) {
    HAL_Delay(1000);
    HAL_GPIO_TogglePin(GPIOC, GPIO_PIN_13);
  }
}
```

四步走:`HAL_Init()` 初始化库,`SystemClock_Config()` 把时钟配到能跑的速度,中间那一坨把 PC13 配成输出点亮板载灯,最后 `while(1)` 里一秒翻转一次电平,灯就闪起来。任何 HAL 裸机程序,骨架都是这个模样。

## 头一段:初始化库和时钟

`HAL_Init()` 必须在所有 HAL 函数之前调用,它干的事笔者先不展开——配中断优先级分组、把 SysTick 设成 1 ms 中断(给 `HAL_Delay` 用的节拍)、初始化 HAL 内部状态。SysTick 是个 24 位倒计数定时器,挂在 Cortex-M3 内核里,完整细节留给后面讲定时器。

`SystemClock_Config()` 定义在 `system.c`,把系统时钟从内部 8 MHz 的 HSI 经 PLL 倍频配到 64 MHz。完整时钟树——HSI/HSE 怎么选、PLL 怎么配、AHB/APB 分频、为什么 72 MHz 要给 Flash 加等待周期——是 P2 的重头戏,这里咱们先认下「时钟配好了」。

## 中间一坨:把 PC13 配成输出

这是模板唯一碰外设的地方,也是配任何 GPIO 都会反复用的套路,两步顺序不能反:先**开时钟**,再**配引脚**。

```c
__HAL_RCC_GPIOC_CLK_ENABLE();
HAL_GPIO_Init(GPIOC, &def);
```

为啥顺序不能反?根因是 STM32 为了省电,所有外设时钟默认关着。时钟没开,寄存器写进去不生效——代码全对,引脚就是没反应。这是新手点灯失败的最高频原因之一,笔者撂这儿,P3 讲 GPIO 时还正面对一遍。

配置结构体 `def`:`Mode` 设 `GPIO_MODE_OUTPUT_PP`(推挽输出),`Pin` 选 `GPIO_PIN_13`,`Speed` 给 `GPIO_SPEED_FREQ_LOW`(LED 慢速够了)。GPIO 八种模式、推挽和开漏差在哪,留给 P3——这里只要知道「推挽输出」能主动输出高、也能主动输出低。

笔者得诚实交代一笔:模板里写了 `def.Pull = GPIO_PULLDOWN`,但**推挽输出模式下这个 `Pull` 字段不起作用**——推挽有上下两个管子主动驱动电平,用不上内部上拉下拉。留着无害,但也别以为它在干啥活。理解这点,比照抄这行重要。

配好结构体,`HAL_GPIO_Init(GPIOC, &def)` 把它写进 GPIOC 控制寄存器,PC13 就配成推挽输出了。

## PC13 那盏灯:低电平才点亮

点灯之前再强调一遍 P0.1 种过的坑:Blue Pill 板载 LED 接 PC13,而且**低电平点亮**(共阳极接法):

```c
HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, GPIO_PIN_SET);  // SET = 高电平 = 灯灭
```

这行把初始状态设成高电平,也就是**灯灭**。循环里每秒翻转一次,灯就「灭→亮→灭」地闪。照抄网上「输出高电平点亮」的代码,这灯死活不亮——根因是这盏灯极性和很多教程反着来。P3 点灯那章会正面收掉。

## system.c:64 MHz 是怎么来的

`SystemClock_Config` 把时钟配到 64 MHz,算式钉死:

```c
osc.PLL.PLLSource = RCC_PLLSOURCE_HSI_DIV2;  /* 4 MHz  */
osc.PLL.PLLMUL    = RCC_PLL_MUL16;           /* 64 MHz */
```

HSI 内部 8 MHz,除以 2 喂 PLL(4 MHz),乘 16 出来 64 MHz,就是 SYSCLK。然后 AHB 不分频(HCLK=64 MHz),APB1 二分频(32 MHz),APB2 不分频(64 MHz)。Blue Pill 有个硬约束:APB1 最高只跑 36 MHz,必须二分频,硬灌会超频死机。至于 HSE、72 MHz、Flash 等待周期那些——全套时钟树留给 P2。

## HAL 模块开关和错误处理

`stm32f1xx_hal_conf.h` 是 HAL 总开关,一串 `#define HAL_xxx_MODULE_ENABLED` 控制编译哪些模块。模板默认全开体积偏大;Flash 紧张时把用不到的模块宏注释掉,代码立刻瘦一圈。

还有个约定提一句:大多数 HAL 函数返回 `HAL_StatusTypeDef`。模板图省事没检查,但正经项目里关键步骤(像时钟配置)笔者建议检查返回值,失败就跳 `Error_Handler()` 死循环。完整的错误处理和 HardFault 怎么查,留给后面。

## 这一章的套路和坑

读完这篇抓住一个套路:**开时钟 → 填配置结构体 → 调 `HAL_xxx_Init`**,这是配任何 HAL 外设的通用节奏,GPIO、USART、定时器都这个路子。

坑拢一下:点灯不亮先怀疑三件——GPIOC 时钟开了没、PC13 是低电平点亮(SET 是灭)、引脚模式配对没。这三个查完,九成「灯不亮」能定位。

---

[上一篇:项目结构](./02_project_structure) | [下一篇:编译与烧录 →](./04_build_and_flash)
