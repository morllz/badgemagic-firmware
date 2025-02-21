cmake_minimum_required(VERSION 3.20)

########################################
# external mrs toolchain 
########################################
include(mrs_toolchain.cmake)

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
if (NOT VERSION_ABBR)
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
    # (other source files omitted for brevity)
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
set(CPU "-march=rv32imac -mabi=ilp32 -msmall-data-limit=8")
set(CMAKE_C_FLAGS "${CPU} ${OPT} -Wall -fdata-sections -ffunction-sections")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror=implicit-function-declaration")

if (DEBUG)
    message(STATUS "Debugging enabled")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -gdwarf-2 -DDEBUG=${DEBUG}")
endif()

if (USBC_VERSION)
    message(STATUS "Building for USB-C version")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSBC_VERSION=${USBC_VERSION}")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DVERSION='\"${VERSION}\"' -DVERSION_ABBR='\"${VERSION_ABBR}\"'")

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

########################################
# build
########################################
message(STATUS "Setting up build commands...")
set(CMAKE_EXECUTABLE_SUFFIX ".elf")
add_executable(${TARGET} ${C_SOURCES} ${ASM_SOURCES})
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
message(STATUS "Adding programming targets...")
add_custom_target(program
    COMMAND sudo wch-openocd -f /usr/share/wch-openocd/openocd/scripts/interface/wch-riscv.cfg -c 'init; halt; program ${BUILD_DIR}/${TARGET}.elf; reset; wlink_reset_resume; exit;'
    DEPENDS ${TARGET}
    COMMENT "Flashing firmware using wch-openocd..."
)

add_custom_target(isp
    COMMAND wchisp flash ${BUILD_DIR}/${TARGET}.bin
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
