---
title: 03 — 代码走读
---

# 03 — 代码走读

模板的 `main.c` 短得吓人，满打满算也就二十来行，可它把 HAL 裸机程序的整套套路全包进去了——初始化库、配时钟、配外设、进死循环干活。笔者带咱们把这几行从头读到尾，套路一通，以后看任何 HAL 程序都不怵。

不过丑话说在前头:这篇只够咱们「看懂模板跑起来」,真要讲透每一处——GPIO 的八种模式、完整时钟树、`HAL_Delay` 为什么阻塞——那是后面 **P2(时钟)**、**P3(GPIO、中断)** 的活,笔者会在该收的地方明确标注「留给后面」,不在环境篇里铺开。

## main.c 的骨架

先把整个 `main` 拎出来看骨架，细节咱们一段段拆：

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

四步走:`HAL_Init()` 把 HAL 库本身初始化好,`SystemClock_Config()` 把系统时钟配到能跑的速度,中间那一坨把 PC13 配成输出点亮板载灯,最后 `while(1)` 死循环里一秒翻转一次电平,灯就闪起来。任何一个 HAL 裸机程序,骨架都是这个模样。

## 头一段:初始化库和时钟

`HAL_Init()` 必须在所有 HAL 函数之前调用,它干的事笔者先不展开——配中断优先级分组、把 SysTick 设成 1 ms 中断(给 `HAL_Delay` 用的那个节拍)、初始化 HAL 内部状态。SysTick 是个 24 位倒计数定时器,挂在 Cortex-M3 内核里,完整的细节留给后面讲定时器的时候。

`SystemClock_Config()` 定义在 `system.c`,它把系统时钟从内部 8 MHz 的 HSI,经 PLL 倍频配到 64 MHz。这个 64 MHz 怎么算出来的,咱们在 `system.c` 那节拆。完整时钟树——HSI/HSE 怎么选、PLL 怎么配、AHB 和 APB1/APB2 怎么分频、72 MHz 时为什么要给 Flash 加等待周期——是 P2 的重头戏,这里咱们先认下「它把时钟配好了」这个结论。

## 中间一坨:把 PC13 配成输出

这是模板唯一碰外设的地方,也是咱们以后配任何 GPIO 都会反复用的套路。它分两步,顺序不能反:先**开时钟**,再**配引脚**。

```c
__HAL_RCC_GPIOC_CLK_ENABLE();
HAL_GPIO_Init(GPIOC, &def);
```

为啥顺序不能反?根因是 STM32 为了省电,所有外设时钟默认是关的,GPIO 也不例外。时钟没开,寄存器写进去根本不生效——代码全对,引脚就是没反应。这是新手点灯失败的最高频原因之一,坑笔者在这儿先撂下,P3 讲 GPIO 时还会正面对一遍。`__HAL_RCC_GPIOC_CLK_ENABLE()` 是个宏,它写的是 RCC 时钟使能寄存器里 GPIOC 对应的那一位。

接着看那个配置结构体 `def`。`Mode` 设成 `GPIO_MODE_OUTPUT_PP`(推挽输出),`Pin` 选 `GPIO_PIN_13`,`Speed` 给 `GPIO_SPEED_FREQ_LOW`(LED 慢速够了,速度越高边沿越陡、功耗和干扰也越大)。GPIO 到底有几种模式、推挽和开漏在电路上差在哪,笔者留给 P3——这里咱们只要知道「推挽输出」就是能主动输出高、也能主动输出低,适合驱动 LED。

这里有个笔者要诚实交代的地方:模板里写了 `def.Pull = GPIO_PULLDOWN`,但**推挽输出模式下这个 `Pull` 字段其实不起作用**——推挽输出有上下两个管子主动驱动电平,用不上内部上拉下拉。留着它无害,但也别误以为它在干啥活。理解这一点,比照抄这行重要。

配好结构体,`HAL_GPIO_Init(GPIOC, &def)` 把它写进 GPIOC 的控制寄存器,PC13 这就算配成推挽输出了。

## PC13 那盏灯:低电平才点亮

点灯之前,笔者得再强调一遍 P0.1 种过草的那个坑:Blue Pill 板载的 LED 接在 PC13 上,而且它是**低电平点亮**的(共阳极接法,LED 正极接 3.3 V,负极接 PC13)。所以代码里:

```c
HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, GPIO_PIN_SET);  // SET = 高电平 = 灯灭
```

这一行把初始状态设成高电平,也就是**灯灭**。然后进循环,每秒翻转一次电平,灯就在「灭→亮→灭」地闪。要是哪天咱们照抄网上「输出高电平点亮」的代码,这盏灯会死活不亮——根因不是代码错,是这盏灯的极性和很多教程反着来。这个坑 P3 点灯那章会正面收掉。

## system.c:64 MHz 是怎么来的

`system.c` 里 `SystemClock_Config` 把时钟配到 64 MHz,笔者带咱们把这条算式钉死:

```c
osc.PLL.PLLSource = RCC_PLLSOURCE_HSI_DIV2;  /* 4 MHz  */
osc.PLL.PLLMUL    = RCC_PLL_MUL16;           /* 64 MHz */
```

HSI 是内部 8 MHz 振荡器,先除以 2 喂给 PLL 当输入(4 MHz),再乘以 16,出来就是 64 MHz,这就是 SYSCLK。然后 AHB 不分频(HCLK = 64 MHz),APB1 二分频(32 MHz),APB2 不分频(64 MHz)。

这里有个 Blue Pill 的硬约束笔者必须提醒:APB1 总线最高只能跑 36 MHz,所以它必须二分频,不能跟着 HCLK 一起跑到 64 MHz——硬灌会超频死机。至于「为什么 HSI 准不准、为什么实际很多板子更想用外部晶振 HSE 跑到 72 MHz、72 MHz 又为什么要给 Flash 配两个等待周期」——全套时钟树的坑和机制,留给 P2。

## HAL 模块的开关和错误处理

`stm32f1xx_hal_conf.h` 是 HAL 库的总开关,里头一串 `#define HAL_xxx_MODULE_ENABLED` 控制编译进哪些模块。模板默认全开,所以编译出来体积偏大;哪天 Flash 紧张了,把用不到的模块宏注释掉,代码立刻能瘦一圈。这就是 [02 章](./02_project_structure)说过的 Flash 省体积手段。

还有个贯穿所有 HAL 调用的约定,笔者提一句:大多数 HAL 函数会返回 `HAL_StatusTypeDef`(`HAL_OK` / `HAL_ERROR` / `HAL_BUSY` / `HAL_TIMEOUT`)。模板里图省事没检查返回值,但正经项目里,像时钟配置这种关键步骤,笔者建议检查一下 `HAL_RCC_OscConfig` 的返回值,失败了就跳进一个 `Error_Handler()` 死循环——出问题时程序能停在已知状态,而不是带着错配置继续跑飞。完整的错误处理和 HardFault 怎么查,留给后面的章节。

## 这一章的套路和坑

读完这篇,咱们应该抓住一个套路:**开时钟 → 填配置结构体 → 调 `HAL_xxx_Init`**,这三步是配任何 HAL 外设的通用节奏,GPIO、USART、定时器全是这个路子。后面学到新外设,套这个模子就行。

坑拢一下:点灯不亮,先怀疑三件事——GPIOC 时钟开了没(`__HAL_RCC_GPIOC_CLK_ENABLE` 漏没漏)、PC13 是低电平点亮(写 SET 是灭不是亮)、引脚模式配对没(推挽输出)。这三个查完,九成的「灯不亮」都能定位。

---

[上一篇:项目结构](./02_project_structure) | [下一篇:编译与烧录 →](./04_build_and_flash)
