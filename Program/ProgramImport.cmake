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
    endif()

    find_package(Perl REQUIRED)

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