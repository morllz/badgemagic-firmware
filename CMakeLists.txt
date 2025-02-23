cmake_minimum_required(VERSION 3.20)

########################################
# external mrs toolchain 
########################################
# includes compiler, linker, objcopy, size
include(mrs_toolchain.cmake)


########################################
# wchisp
########################################
# only get downloaded if no local install is found
include(wchisp.cmake)


######################################
# project
########################################
message(STATUS "Setting up project: badgemagic-firmware")
project(badgemagic-firmware C ASM)


########################################
# building variables
########################################
option(DEBUG "Enable debugging" OFF)
option(USBC_VERSION "Build for USB-C version" ON)

set(OPT "-Os")


########################################
# Get current version
########################################
message(STATUS "Retrieving project version from Git...")
execute_process(COMMAND git describe --tags --dirty OUTPUT_VARIABLE VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND git describe --abbrev=0 --tags OUTPUT_VARIABLE VERSION_ABBR OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT VERSION_ABBR)
    set(VERSION_ABBR "unknown")
    message(WARNING "Unable to determine version from git tags")
else()
    message(STATUS "Project version: ${VERSION}")
endif()


########################################
# target
########################################
set(TARGET badgemagic-ch582)
message(STATUS "Target set to: ${TARGET}")


########################################
# paths
########################################
set(BUILD_DIR ${CMAKE_BINARY_DIR}/build)
message(STATUS "Build directory: ${BUILD_DIR}")


########################################
# source
########################################
message(STATUS "Configuring source files...")
set(C_SOURCES
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_i2c.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_timer2.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_spi0.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_gpio.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_pwr.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_uart3.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_uart2.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_sys.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_clk.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_uart0.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_timer1.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_pwm.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_adc.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_timer3.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_timer0.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_flash.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_uart1.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_usb2dev.c
    CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_spi1.c
    CH5xx_ble_firmware_library/RVMSIS/core_riscv.c
    src/main.c
    src/debug.c
    src/leddrv.c
    src/button.c
    src/bmlist.c
    src/ble/profile/legacy.c
    src/ble/profile/batt.c
    src/ble/profile/devinfo.c
    src/ble/profile/ng.c
    src/config.c
    src/legacyctrl.c
    src/util/crc.c
    src/ngctrl.c
    src/ble/setup.c
    src/ble/peripheral.c
    src/data.c
    src/usb/utils.c
    src/usb/setup.c
    src/usb/ctrl.c
    src/usb/debug.c
    src/usb/dev.c
    src/usb/composite/hiddev.c
    src/usb/composite/cdc-serial.c
    src/xbm.c
    src/resource.c
    src/animation.c
    src/font.c
    src/power.c
)

set(ASM_SOURCES
    CH5xx_ble_firmware_library/Startup/startup_CH583.S
)


########################################
# includes
########################################
message(STATUS "Setting up include directories...")
include_directories(
    CH5xx_ble_firmware_library/StdPeriphDriver/inc
    CH5xx_ble_firmware_library/RVMSIS
    CH5xx_ble_firmware_library/Core
    CH5xx_ble_firmware_library/BLE
)


########################################
# CFLAGS
########################################
message(STATUS "Configuring compiler flags...")
# cpu
set(CPU "-march=rv32imac -mabi=ilp32 -msmall-data-limit=8")

# fpu
set(FPU "")

# float-abi
set(FLOAT-ABI "")

# mcu
set(MCU "${CPU} ${FPU} ${FLOAT-ABI}")

# compile flags
set(CMAKE_ASM_FLAGS "${MCU} ${OPT} -Wall -fdata-sections -ffunction-sections")


set(CMAKE_C_FLAGS "${MCU} ${OPT} -Wall -fdata-sections -ffunction-sections")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror=implicit-function-declaration")

if(DEBUG)
    message(STATUS "Debugging enabled")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -gdwarf-2 -DDEBUG=${DEBUG}")
endif()

if(USBC_VERSION)
    message(STATUS "Building for USB-C version")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSBC_VERSION=${USBC_VERSION}")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DVERSION='\"${VERSION}\"' -DVERSION_ABBR='\"${VERSION_ABBR}\"'")

# Generate dependency information
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -MMD -MP")


########################################
# LDFLAGS
########################################
message(STATUS "Configuring linker flags...")
set(LDSCRIPT CH5xx_ble_firmware_library/Ld/Link.ld)
set(LIBS
    -lc -lm -lnosys
    ${CMAKE_SOURCE_DIR}/CH5xx_ble_firmware_library/StdPeriphDriver/libISP583.a
    ${CMAKE_SOURCE_DIR}/CH5xx_ble_firmware_library/BLE/LIBCH58xBLE.a
)

set(CMAKE_EXE_LINKER_FLAGS "${MCU} -mno-save-restore -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -Wunused -Wuninitialized")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -T ${LDSCRIPT} -nostartfiles -Wl,--gc-sections -Wl,-Map=${BUILD_DIR}/${TARGET}.map --specs=nano.specs --specs=nosys.specs")


########################################
# build
########################################
message(STATUS "Setting up build commands...")

set(CMAKE_EXECUTABLE_SUFFIX ".elf")

add_executable(${TARGET} ${C_SOURCES} ${ASM_SOURCES})

set_target_properties(${TARGET}
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/build"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/build"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/build"
)

target_link_libraries(${TARGET} ${LIBS})

add_custom_command(TARGET ${TARGET} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${BUILD_DIR}
    COMMENT "Ensuring build directory exists..."
)

add_custom_command(TARGET ${TARGET} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${TARGET}> ${BUILD_DIR}/${TARGET}.hex
    COMMAND ${CMAKE_OBJCOPY} -O binary -S $<TARGET_FILE:${TARGET}> ${BUILD_DIR}/${TARGET}.bin
    COMMENT "Generating HEX and BIN files..."
)


########################################
# program
########################################
#message(STATUS "Adding programming targets...")
#add_custom_target(program
#    COMMAND sudo wch-openocd -f /usr/share/wch-openocd/openocd/scripts/interface/wch-riscv.cfg -c 'init; halt; program ${BUILD_DIR}/${TARGET}.elf; reset; wlink_reset_resume; exit;'
#    DEPENDS ${TARGET}
#    COMMENT "Flashing firmware using wch-openocd..."
#)

add_custom_target(isp
    COMMAND ${WCHISP_COMMAND} flash ${BUILD_DIR}/${TARGET}.bin
    DEPENDS ${TARGET}
    COMMENT "Flashing firmware using wchisp..."
)


########################################
# clean up
########################################
message(STATUS "Adding clean-up targets...")
add_custom_target(clean-all
    COMMAND ${CMAKE_BUILD_TOOL} clean
    COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/*
    COMMENT "Cleaning all build artifacts..."
)

set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${PROJECT_NAME}.hex;${PROJECT_NAME}.bin;${PROJECT_NAME}.map")