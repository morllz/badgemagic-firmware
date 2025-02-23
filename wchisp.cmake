message(STATUS "Testing for local wchisp installation...")
execute_process(COMMAND wchisp RESULT_VARIABLE WCHISP_RESULT)

if(NOT WCHISP_RESULT EQUAL 0)
    message(FATAL_ERROR "wchisp not found")
    set(LOCAL_WCHISP OFF)
else()
    message(STATUS "wchisp found")
    set(DOWNLOAD_WCHISP ON)
endif()


set(WCHISP_COMMAND wchisp)

if(!LOCAL_WCHISP)

    if(LINUX)
        message(STATUS "Setting up wchisp for Linux...")
        set(WCHISP_URL https://github.com/ch32-rs/wchisp/releases/download/v0.3.0/wchisp-v0.3.0-linux-x64.tar.gz)
        set(WCHISP_URL_HASH SHA256=67E3D4EB0FFD3CC610D8927E3C3F452E2110531A3F14405DCAEF87DF219F200D)
        set(WCHISP_URI "wchisp-linux-x64")
        set(BINARY_SUFFIX "")
    endif()
    if(WIN32)
        message(STATUS "Setting up wchisp for Windows...")
        set(WCHISP_URL https://github.com/ch32-rs/wchisp/releases/download/v0.3.0/wchisp-v0.3.0-win-x64.zip)
        set(WCHISP_URL_HASH SHA256=EBA605BBC62F217F6454E7236D04EF1B8A6B4396DD7CE8DC26FC83016213C3AA)
        set(WCHISP_URI "wchisp-win-x64")
        set(BINARY_SUFFIX ".exe")
    endif()
    if(APPLE)
        message(STATUS "Setting up wchisp for MacOS...")
        set(WCHISP_URL https://github.com/ch32-rs/wchisp/releases/download/v0.3.0/wchisp-v0.3.0-macos-x64.tar.gz)
        set(WCHISP_URL_HASH SHA256=EBBF46B0C64BB356CD58DA2683C8809C50BDFE2181969F544933D24C8846F608)
        set(WCHISP_URI "wchisp-macos-x64")
        set(BINARY_SUFFIX "")
    endif()

    message(STATUS "Creating wchisp directory...")
    file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/wchisp)
    message(STATUS "Downloading wchisp from: ${WCHISP_URL}")
    file(DOWNLOAD ${WCHISP_URL} ${CMAKE_SOURCE_DIR}/wchisp/wchisp.zip
        EXPECTED_HASH ${WCHISP_URL_HASH}
        SHOW_PROGRESS
    )

    if(NOT EXISTS ${CMAKE_SOURCE_DIR}/wchisp/wchisp${BINARY_SUFFIX})
        message(STATUS "Extracting MRS Toolchain files...")
        file(ARCHIVE_EXTRACT INPUT ${CMAKE_SOURCE_DIR}/wchisp/wchisp.zip
            DESTINATION ${CMAKE_SOURCE_DIR}/wchisp
            TOUCH
        )
    endif()

    set(WCHISP_COMMAND "${CMAKE_SOURCE_DIR}/wchisp/${WCHISP_URI}/wchisp${BINARY_SUFFIX}")
endif()

message(STATUS "wchisp command: ${WCHISP_COMMAND}")