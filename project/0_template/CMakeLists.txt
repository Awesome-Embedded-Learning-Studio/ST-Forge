cmake_minimum_required(VERSION 3.16)

set(CMAKE_SYSTEM_NAME      Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)

set(CMAKE_C_COMPILER       arm-none-eabi-gcc)
set(CMAKE_ASM_COMPILER     arm-none-eabi-gcc)
set(CMAKE_OBJCOPY          arm-none-eabi-objcopy)
set(CMAKE_SIZE             arm-none-eabi-size)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

project(STM32F1 
        VERSION 0.0.1
        LANGUAGES C ASM)

set(CMAKE_C_STANDARD 23)

set(STM32F1_ROOT ${CMAKE_SOURCE_DIR}/../../third_party/STM32CubeF1/Drivers)
set(CMSIS_TMPL   ${STM32F1_ROOT}/CMSIS/Device/ST/STM32F1xx/Source/Templates)

file(GLOB HAL_SRC
    ${STM32F1_ROOT}/STM32F1xx_HAL_Driver/Src/*.c
)

list(FILTER HAL_SRC EXCLUDE REGEX ".*_template\\.c$")

add_compile_options(
    -mcpu=cortex-m3
    -mthumb
    -O2
    -Wall
    -Wextra
    -Wno-missing-field-initializers
    -ffunction-sections
    -fdata-sections
    -DUSE_HAL_DRIVER
    -DSTM32F103xB
)

add_executable(${PROJECT_NAME}.elf 
    main.c
    firmware/system.c
    ${CMSIS_TMPL}/system_stm32f1xx.c
    ${CMSIS_TMPL}/gcc/startup_stm32f103xb.s
    ${HAL_SRC})

target_include_directories(${PROJECT_NAME}.elf PRIVATE
    ${CMAKE_SOURCE_DIR}/firmware                                          # stm32f1xx_hal_conf.h
    ${STM32F1_ROOT}/CMSIS/Include
    ${STM32F1_ROOT}/CMSIS/Device/ST/STM32F1xx/Include
    ${STM32F1_ROOT}/STM32F1xx_HAL_Driver/Inc
)

target_link_options(${PROJECT_NAME}.elf PRIVATE
    -mcpu=cortex-m3
    -mthumb
    -flto
    -T${CMAKE_SOURCE_DIR}/firmware/STM32F103C8TX_FLASH.ld
    -nostartfiles
    -specs=nano.specs
    -specs=nosys.specs
    -Wl,--gc-sections
    -Wl,-Map=${PROJECT_NAME}.map
)

# ── 构建后处理：生成 .bin 并打印 size ────────────────────────────────────────
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY}
            -O binary
            $<TARGET_FILE:${PROJECT_NAME}.elf>
            ${PROJECT_NAME}.bin
    COMMAND ${CMAKE_SIZE}
            --format=berkeley
            $<TARGET_FILE:${PROJECT_NAME}.elf>
    COMMENT "Generating ${PROJECT_NAME}.bin"
)

# ── 烧录目标：make flash ─────────────────────────────────────────────────────
add_custom_target(flash
    COMMAND openocd
            -f interface/stlink.cfg
            -f target/stm32f1x.cfg
            -c "program ${PROJECT_NAME}.bin verify reset exit 0x08000000"
    DEPENDS ${PROJECT_NAME}.elf
    COMMENT "Flashing ${PROJECT_NAME}.bin via OpenOCD"
)

# ── 擦除目标：make erase ─────────────────────────────────────────────────────
add_custom_target(erase
    COMMAND openocd
            -f interface/stlink.cfg
            -f target/stm32f1x.cfg
            -c "init; halt; stm32f1x mass_erase 0; exit"
    COMMENT "Erasing STM32 Flash"
)
