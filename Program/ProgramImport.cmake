include(FetchContent)
include(ExternalProject)

set(OCMAKEUTIL_PROGRAM_PATH ${CMAKE_CURRENT_FUNCTION_LIST_DIR})

FUNCTION(ImportProgram ProgramName)
    set(options)
    set(oneValueArgs URL BIT)
    set(multiValueArgs)

    cmake_parse_arguments(IMPORT_PROGRAM "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    cmake_host_system_information(RESULT HOST_IS_64BIT QUERY IS_64BIT)

    if(NOT IMPORT_PROGRAM_BIT)
        if(${HOST_IS_64BIT})
            set(IMPORT_PROGRAM_BIT 64)
        else()
            set(IMPORT_PROGRAM_BIT 32)
        endif()
    endif()

    if(IMPORT_PROGRAM_BIT EQUAL 64)
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_64")
    else()
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_32")
    endif()

    string(TOLOWER ${ProgramName} ProgramName_Lower)
    string(TOUPPER ${ProgramName} ProgramName_Upper)
    set(WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/external/${ProgramName_Lower}${WORKING_DIRECTORY_SUFFIX})

    if(ProgramName STREQUAL "NASM")
        include(CMakeDetermineASM_NASMCompiler)

        if(NOT CMAKE_ASM_NASM_COMPILER)
            ImportNASM()
        endif()
    else()
        find_package(${ProgramName})

        if(NOT ${ProgramName}_FOUND)
            if(ProgramName STREQUAL "Perl")
                ImportPERL()
            elseif(ProgramName STREQUAL "Python3")
                ImportPython3()
            elseif(ProgramName STREQUAL "protoc")
                Importprotoc()
            else()
                message(STATUS "no Program ${ProgramName} to import")
            endif()
        else()
            if(${ProgramName}_EXECUTABLE)
                message(STATUS "Before Import Find ${ProgramName} EXE :${${ProgramName}_EXECUTABLE}")
            elseif(${ProgramName_Upper}_EXECUTABLE)
                message(STATUS "Before Import Find ${ProgramName} EXE :${${ProgramName_Upper}_EXECUTABLE}")
            endif()
        endif()
    endif()
ENDFUNCTION(ImportProgram)

FUNCTION(ImportPERL)
    set(STRAWBERRY_PERL_PATH ${WORKING_DIRECTORY}/strawberry-perl)
    list(APPEND CMAKE_SYSTEM_PROGRAM_PATH "${STRAWBERRY_PERL_PATH}/perl/bin")

    # list(APPEND CMAKE_SYSTEM_PROGRAM_PATH "${STRAWBERRY_PERL_PATH}/perl/site/bin")
    # list(APPEND CMAKE_SYSTEM_PROGRAM_PATH "${STRAWBERRY_PERL_PATH}/c/bin")
    # find_program(PERL_EXECUTABLE NAMES perl DOC "perl Locator" REQUIRED)
    find_package(Perl)

    if(NOT Perl_FOUND)
        if(NOT IMPORT_PROGRAM_URL)
            message(FATAL_ERROR "URL NOT SET")

            if(HOST_IS_64BIT)
                set(IMPORT_PROGRAM_URL https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_53822_64bit/strawberry-perl-5.38.2.2-64bit-portable.zip)
            else()
                set(IMPORT_PROGRAM_URL https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-32bit-portable.zip)
            endif()
        endif()

        FetchContent_Declare(download_perl
            PREFIX ${WORKING_DIRECTORY}
            URL ${IMPORT_PROGRAM_URL}
            DOWNLOAD_NO_EXTRACT false
            DOWNLOAD_EXTRACT_TIMESTAMP false
        )
        FetchContent_MakeAvailable(download_perl)
        FetchContent_GetProperties(download_perl)
        file(RENAME ${download_perl_SOURCE_DIR} ${STRAWBERRY_PERL_PATH})
        find_package(Perl REQUIRED)
    endif()

    set(CMAKE_SYSTEM_PROGRAM_PATH ${CMAKE_SYSTEM_PROGRAM_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportPERL)

FUNCTION(ImportNASM)
    set(NASM_PATH ${WORKING_DIRECTORY}/nasm)
    list(APPEND CMAKE_SYSTEM_PROGRAM_PATH "${NASM_PATH}")
    include(CMakeDetermineASM_NASMCompiler)

    if(NOT CMAKE_ASM_NASM_COMPILER)
        if(NOT IMPORT_PROGRAM_URL)
            message(FATAL_ERROR "URL NOT SET")

            if(HOST_IS_64BIT)
                set(NASM_URL https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/nasm-2.16.03-win64.zip)
            else()
                set(NASM_URL https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win32/nasm-2.16.03-win32.zip)
            endif()
        endif()

        FetchContent_Declare(download_nasm
            PREFIX ${WORKING_DIRECTORY}
            URL ${NASM_URL}
            DOWNLOAD_NO_EXTRACT false
            DOWNLOAD_EXTRACT_TIMESTAMP false
        )
        FetchContent_MakeAvailable(download_nasm)
        FetchContent_GetProperties(download_nasm)
        file(RENAME ${download_nasm_SOURCE_DIR} ${NASM_PATH})
        include(CMakeDetermineASM_NASMCompiler)

        if(NOT CMAKE_ASM_NASM_COMPILER)
            message(FATAL_ERROR "NASM NOT FOUND")
        endif()
    endif()

    set(CMAKE_SYSTEM_PROGRAM_PATH ${CMAKE_SYSTEM_PROGRAM_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportNASM)

FUNCTION(ImportPython3)
    set(WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/external/${ProgramName_Lower})
    set(PYTHON3_PATH ${WORKING_DIRECTORY}/python3)
    list(APPEND CMAKE_SYSTEM_PROGRAM_PATH "${PYTHON3_PATH}")
    find_package(Python3)

    if(NOT Python3_FOUND)
        if(NOT IMPORT_PROGRAM_URL)
            message(FATAL_ERROR "URL NOT SET")

            if(HOST_IS_64BIT)
                set(IMPORT_PROGRAM_URL https://mirrors.aliyun.com/python-release/windows/python-3.13.5-embed-amd64.zip)
            else()
                set(IMPORT_PROGRAM_URL https://mirrors.aliyun.com/python-release/windows/python-3.13.4-embed-win32.zip)
            endif()
        endif()

        FetchContent_Declare(download_python3
            PREFIX ${WORKING_DIRECTORY}
            URL ${IMPORT_PROGRAM_URL}
            DOWNLOAD_NO_EXTRACT false
            DOWNLOAD_EXTRACT_TIMESTAMP false
        )
        FetchContent_MakeAvailable(download_python3)
        FetchContent_GetProperties(download_python3)
        file(RENAME ${download_python3_SOURCE_DIR} ${PYTHON3_PATH})
        find_package(Python3 REQUIRED)

        # https://www.youtube.com/watch?v=pQj4b7azNLY
        file(DOWNLOAD https://bootstrap.pypa.io/get-pip.py ${PYTHON3_PATH}/get-pip.py
            STATUS status
            SHOW_PROGRESS
        )
        execute_process(COMMAND ${Python_EXECUTABLE} ${PYTHON3_PATH}/get-pip.py)
        file(GLOB PATH_FILE "*._pth")
        list(LENGTH PATH_FILE PATH_FILE_LENGTH)

        if(PATH_FILE_LENGTH EQUAL 1)
            file(READ ${PATH_FILE} PATH_FILE_CONTENTS)
            string(APPEND PATH_FILE_CONTENTS "Lib\\site-packages\\n")
            file(WRITE ${PATH_FILE} "${PATH_FILE_CONTENTS}")
        else()
            message(FATAL_ERROR "Python _pth file not found or multiple found: ${PATH_FILE}")
        endif()
    endif()

    set(CMAKE_SYSTEM_PROGRAM_PATH ${CMAKE_SYSTEM_PROGRAM_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportPython3)

FUNCTION(Importprotoc)
    set(protoc_PATH ${WORKING_DIRECTORY}/protoc)
    list(FIND CMAKE_SYSTEM_PROGRAM_PATH "${protoc_PATH}/bin" FIND_RES)

    if(FIND_RES GREATER -1)
        return()
    endif()

    list(APPEND CMAKE_SYSTEM_PROGRAM_PATH "${protoc_PATH}/bin")

    if(NOT EXISTS ${protoc_PATH}/bin/protoc.exe)
        if(NOT IMPORT_PROGRAM_URL)
            message(FATAL_ERROR "URL NOT SET")

            if(HOST_IS_64BIT)
                set(IMPORT_PROGRAM_URL https://github.com/protocolbuffers/protobuf/releases/download/v31.1/protoc-31.1-win64.zip)
            else()
                set(IMPORT_PROGRAM_URL https://github.com/protocolbuffers/protobuf/releases/download/v31.1/protoc-31.1-win32.zip)
            endif()
        endif()

        FetchContent_Declare(download_protoc
            PREFIX ${WORKING_DIRECTORY}
            URL ${IMPORT_PROGRAM_URL}
            DOWNLOAD_NO_EXTRACT false
            DOWNLOAD_EXTRACT_TIMESTAMP false
        )
        FetchContent_MakeAvailable(download_protoc)
        FetchContent_GetProperties(download_protoc)
        file(RENAME ${download_protoc_SOURCE_DIR} ${protoc_PATH})
    endif()

    set(CMAKE_SYSTEM_PROGRAM_PATH ${CMAKE_SYSTEM_PROGRAM_PATH} CACHE INTERNAL "")
    set(protoc_PATH ${protoc_PATH} CACHE INTERNAL "")
ENDFUNCTION(Importprotoc)
