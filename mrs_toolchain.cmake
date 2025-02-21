if(LINUX)
    message(STATUS "Setting up toolchain for Linux...")
    set(MRS_TOOLCHAIN_URL https://github.com/ch32-riscv-ug/MounRiver_Studio_Community_miror/releases/download/1.92-toolchain/MRS_Toolchain_Linux_x64_V1.92.tar.xz)
    set(MRS_TOOLCHAIN_URL_HASH SHA256=33E0DD7581A2EEA25BC5D1AA2C31F5C8B316E543B954D84F9E1FFC5999E93FEA)
    set(MRS_TOOLCHAIN_URI "MRS_Toolchain_Linux_x64_V1.92/RISC-V_Embedded_GCC")
    set(BINARY_SUFFIX "")
endif()

if(WIN32)
    message(STATUS "Setting up toolchain for Windows...")
    set(MRS_TOOLCHAIN_URL https://github.com/ch32-riscv-ug/MounRiver_Studio_Community_miror/releases/download/1.92-toolchain/MRS_Toolchain_Win_V1.92.zip)
    set(MRS_TOOLCHAIN_URL_HASH SHA256=D5633D7659631FC1BA095624FFD4218908792E03F53C7080335454D3110CD18E)
    set(MRS_TOOLCHAIN_URI "MRS_Toolchain_Win_V1.92/RISC-V Embedded GCC")
    set(BINARY_SUFFIX ".exe")
endif()

if(APPLE)
    message(STATUS "Setting up toolchain for macOS...")
    set(MRS_TOOLCHAIN_URL https://github.com/ch32-riscv-ug/MounRiver_Studio_Community_miror/releases/download/1.92-toolchain/MRS_Toolchain_MAC_V192.zip)
    set(MRS_TOOLCHAIN_URL_HASH SHA256=DA2B3A2BAEF073E3AFD61F6D7CB88E5A905E7C9CBA1B44C2684EFD84AD606274)
    set(MRS_TOOLCHAIN_URI "MRS_Toolchain_MAC_V192/RISC-V_Embedded_GCC")
    set(BINARY_SUFFIX "")
endif()

message(STATUS "Creating toolchain directory...")
file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/MRS_Toolchain)

message(STATUS "Downloading MRS Toolchain from: ${MRS_TOOLCHAIN_URL}")
file(DOWNLOAD ${MRS_TOOLCHAIN_URL} ${CMAKE_SOURCE_DIR}/MRS_Toolchain/toolchain.zip
    EXPECTED_HASH ${MRS_TOOLCHAIN_URL_HASH}
    SHOW_PROGRESS
)

if(NOT EXISTS ${CMAKE_SOURCE_DIR}/MRS_Toolchain/${MRS_TOOLCHAIN_URI})
    message(STATUS "Extracting MRS Toolchain files...")
    file(ARCHIVE_EXTRACT INPUT ${CMAKE_SOURCE_DIR}/MRS_Toolchain/toolchain.zip 
        DESTINATION ${CMAKE_SOURCE_DIR}/MRS_Toolchain
        TOUCH
    )
endif()

message(STATUS "Configuring toolchain as compiler...")
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv)

set(TOOLCHAIN_DIR "${CMAKE_SOURCE_DIR}/MRS_Toolchain/${MRS_TOOLCHAIN_URI}")
set(CMAKE_C_COMPILER "${TOOLCHAIN_DIR}/bin/riscv-none-embed-gcc${BINARY_SUFFIX}")
set(CMAKE_ASM_COMPILER "${TOOLCHAIN_DIR}/bin/riscv-none-embed-gcc${BINARY_SUFFIX}")
set(CMAKE_OBJCOPY "${TOOLCHAIN_DIR}/bin/riscv-none-embed-objcopy${BINARY_SUFFIX}")
set(CMAKE_SIZE "${TOOLCHAIN_DIR}/bin/riscv-none-embed-size${BINARY_SUFFIX}")
