cmake_minimum_required(VERSION 3.24)
include(RegexHelper)

FUNCTION(FindInPath ProjectName Path)
    set(options CONFIG REQUIRED)
    set(oneValueArgs)
    set(multiValueArgs)

    cmake_parse_arguments(FindInPath "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    list(APPEND CMAKE_PREFIX_PATH ${Path})

    if(FindInPath_CONFIG)
        set(config_parameter CONFIG)
    else()
        set(config_parameter)
    endif()

    if(FindInPath_REQUIRED)
        set(required_parameter REQUIRED)
    else()
        set(required_parameter)
    endif()

    find_package(${ProjectName} ${config_parameter} ${required_parameter})

    if(${ProjectName}_FOUND)
        set(FindInPath_FOUND TRUE PARENT_SCOPE)
    else()
        set(FindInPath_FOUND FALSE PARENT_SCOPE)
    endif()
ENDFUNCTION(FindInPath)

FUNCTION(AddPathToPrefix Path)
    list(APPEND CMAKE_PREFIX_PATH ${Path})
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
ENDFUNCTION(AddPathToPrefix)

FUNCTION(PostImportProject)
    find_package(${ProjectName})

    if(ProjectName STREQUAL "TBB")
        target_compile_definitions(TBB::tbb INTERFACE -D__TBB_BUILD=1)
    elseif(ProjectName STREQUAL "SQLite3")
        find_package(SQLite3_a CONFIG REQUIRED)
    endif()
ENDFUNCTION(PostImportProject)

FUNCTION(ImportProject ProjectName)
    set(options STATIC_CRT STATIC SSH FIND)
    set(oneValueArgs URL TAG BIT EXTERNAL_DIR)
    set(multiValueArgs)

    cmake_parse_arguments(IMPORT_PROJECT "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_${CMAKE_CXX_COMPILER_ID}")

    if(IMPORT_PROJECT_STATIC_CRT)
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_STATIC_CRT")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_STATIC")
    endif()

    if(NOT IMPORT_PROJECT_BIT)
        MATH(EXPR IMPORT_PROJECT_BIT "${CMAKE_SIZEOF_VOID_P}*8")
    endif()

    if(IMPORT_PROJECT_BIT EQUAL 64)
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_64")
    else()
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_32")
    endif()

    if(IMPORT_PROJECT_TAG)
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_${IMPORT_PROJECT_TAG}")
    endif()

    string(TOLOWER ${ProjectName} ProjectName_Lower)

    if(IMPORT_PROJECT_EXTERNAL_DIR)
        set(WORKING_DIRECTORY ${IMPORT_PROJECT_EXTERNAL_DIR}/${ProjectName_Lower}${WORKING_DIRECTORY_SUFFIX})
    else()
        set(WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/../external/${ProjectName_Lower}${WORKING_DIRECTORY_SUFFIX})
        cmake_path(NORMAL_PATH WORKING_DIRECTORY)
    endif()

    list(APPEND CMAKE_GENERATOR_ARGV "-G")
    list(APPEND CMAKE_GENERATOR_ARGV "${CMAKE_GENERATOR}")

    # message(STATUS "CMAKE_GENERATOR_PLATFORM $<$<BOOL:CMAKE_GENERATOR_PLATFORM>:-A ${CMAKE_GENERATOR_PLATFORM}>")
    if(CMAKE_GENERATOR_PLATFORM)
        list(APPEND CMAKE_GENERATOR_ARGV "-A")
        list(APPEND CMAKE_GENERATOR_ARGV "${CMAKE_GENERATOR_PLATFORM}")
    endif()

    # set(CMAKE_FIND_DEBUG_MODE ON)
    find_package(${ProjectName} CONFIG)

    if(NOT ${ProjectName}_FOUND)
        find_package(${ProjectName})
    endif()

    if(NOT ${ProjectName}_FOUND)
        if(IMPORT_PROJECT_TAG)
            IsSHA1String(IMPORT_PROJECT_TAG BGIT_TAG_SHA1)

            if(BGIT_TAG_SHA1)
                set(GIT_SHALLOW_VAL FALSE)
            else()
                set(GIT_SHALLOW_VAL TRUE)
            endif()
        endif()

        if(ProjectName STREQUAL "ZLIB")
            ImportZLIB()
        elseif(ProjectName STREQUAL "CURL")
            ImportCURL()
        elseif(ProjectName STREQUAL "SQLite3")
            ImportSQLITE3()
        elseif(ProjectName STREQUAL "libuv")
            ImportLIBUV()
        elseif(ProjectName STREQUAL "Detours")
            ImportDETOURS()
        elseif(ProjectName STREQUAL "SDL2")
            ImportSDL2()
        elseif(ProjectName STREQUAL "SDL3")
            ImportSDL3()
        elseif(ProjectName STREQUAL "SDL2_image")
            ImportSDL2_image()
        elseif(ProjectName STREQUAL "SDL3_image")
            ImportSDL3_image()
        elseif(ProjectName STREQUAL "MbedTLS")
            ImportMbedTLS()
        elseif(ProjectName STREQUAL "GLEW")
            ImportGLEW()
        elseif(ProjectName STREQUAL "rapidfuzz")
            ImportRAPIDFUZZ()
        elseif(ProjectName STREQUAL "xxHash")
            ImportxxHash()
        elseif(ProjectName STREQUAL "zstd")
            ImportZSTD()
        elseif(ProjectName STREQUAL "Boost")
            ImportBOOST()
        elseif(ProjectName STREQUAL "OpenSSL")
            ImportOPENSSL()
        elseif(ProjectName STREQUAL "qiniu")
            ImportQINIU()
        elseif(ProjectName STREQUAL "folly")
            ImportFOLLY()
        elseif(ProjectName STREQUAL "TBB")
            ImportTBB()
        elseif(ProjectName STREQUAL "minizip")
            ImportMINIZIP()
        elseif(ProjectName STREQUAL "Steam")
            ImportSTEAM()
        elseif(ProjectName STREQUAL "cpuid")
            ImportCPUID()
        elseif(ProjectName STREQUAL "Protobuf")
            ImportProtobuf()
        elseif(ProjectName STREQUAL "libwebsockets")
            ImportLIBWEBSOCKETS()
        elseif(ProjectName STREQUAL "absl")
            ImportABSL()
        elseif(ProjectName STREQUAL "simdjson")
            ImportSIMDJSON()
        elseif(ProjectName STREQUAL "RapidJSON")
            ImportRAPIDJSON()
        elseif(ProjectName STREQUAL "sqlpp23")
            ImportSQLPP23()
        elseif(ProjectName STREQUAL "DirectXTex")
            ImportDirectXTex()
        elseif(ProjectName STREQUAL "CapnProto")
            ImportCapnProto()
        else()
            message(FATAL_ERROR "no project ${ProjectName} to import")
        endif()
    else()
        message(STATUS "Before Import Find ${ProjectName}")

        if(${ProjectName}_DIR)
            message(STATUS "Before Import Find ${ProjectName} DIR :${${ProjectName}_DIR}")
        endif()

        if(${ProjectName}_INCLUDE_DIR)
            message(STATUS "Before Import Find ${ProjectName} INCLUDE_DIR :${${ProjectName}_INCLUDE_DIR}")
        endif()
    endif()

    PostImportProject()
ENDFUNCTION(ImportProject)

FUNCTION(ImportZLIB)
    if(IMPORT_PROJECT_STATIC)
        set(ZLIB_USE_STATIC_LIBS "ON" PARENT_SCOPE)
    endif()

    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    if(IMPORT_PROJECT_TAG)
        set(ZLIB_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(ZLIB_TAG "04f42ceca40f73e2978b50e93806c2a18c1281fc") # v1.2.13
        message(SEND_ERROR "missing ZLIB tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:madler/zlib.git")
    else()
        set(GIT_REPOSITORY "https://github.com/madler/zlib.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportZLIB)

FUNCTION(ImportCURL)
    # already define CMAKE_DEBUG_POSTFIX
    # build_shared or static
    if(IMPORT_PROJECT_STATIC)
        set(CURL_USE_STATIC_LIBS "ON" PARENT_SCOPE)
    endif()

    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CURL_STATIC_CRT ON)
    else()
        set(CURL_STATIC_CRT OFF)
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(FATAL_ERROR "missing CURL tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:curl/curl.git")
    else()
        set(GIT_REPOSITORY "https://github.com/curl/curl.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Debug
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportCURL)

FUNCTION(ImportSQLITE3)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR}/${ProjectName} CONFIG)

    if(FindInPath_FOUND)
        FindInPath(${ProjectName}_a ${${ProjectName}_INSTALL_DIR}/${ProjectName}_a CONFIG)

        if(FindInPath_FOUND)
            AddPathToPrefix(${${ProjectName}_INSTALL_DIR}/${ProjectName})
            AddPathToPrefix(${${ProjectName}_INSTALL_DIR}/${ProjectName}_a)
            return()
        endif()
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(SQLITE_STATIC TRUE)
    else()
        set(SQLITE_STATIC FALSE)
    endif()

    if(IMPORT_PROJECT_URL)
        set(SQLITE_AMALGAMATION_URL ${IMPORT_PROJECT_URL})
    endif()

    # message(STATUS "CMAKE_COMMAND:" ${CMAKE_COMMAND})
    # message(STATUS "CMAKE_GENERATOR_ARGV:" ${CMAKE_GENERATOR_ARGV})
    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR}/${ProjectName} CONFIG REQUIRED)
    FindInPath(${ProjectName}_a ${${ProjectName}_INSTALL_DIR}/${ProjectName}_a CONFIG REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR}/${ProjectName})
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR}/${ProjectName}_a)
ENDFUNCTION(ImportSQLITE3)

FUNCTION(ImportLIBUV)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    if(IMPORT_PROJECT_TAG)
        set(LIBUV_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(LIBUV_TAG "0c1fa696aa502eb749c2c4735005f41ba00a27b8") # v1.44.2
        message(SEND_ERROR "missing libuv tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:libuv/libuv.git")
    else()
        set(GIT_REPOSITORY "https://github.com/libuv/libuv.git")
    endif()

    # set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT")
    # set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd")
    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportLIBUV)

FUNCTION(ImportDETOURS)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix/src/${ProjectName_Lower})
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_TAG)
        set(DETOURS_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(DETOURS_TAG "4b8c659f549b0ab21cf649377c7a84eb708f5e68")
        message(SEND_ERROR "missing DETOURS tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:microsoft/Detours.git")
    else()
        set(GIT_REPOSITORY "https://github.com/microsoft/Detours.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportDETOURS)

FUNCTION(ImportSDL2)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(FATAL_ERROR "missing SDL2 tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:libsdl-org/SDL.git")
    else()
        set(GIT_REPOSITORY "https://github.com/libsdl-org/SDL.git")
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportSDL2)

FUNCTION(ImportSDL3)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(FATAL_ERROR "missing SDL tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:libsdl-org/SDL.git")
    else()
        set(GIT_REPOSITORY "https://github.com/libsdl-org/SDL.git")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(SDL_SHARED FALSE)
    else()
        set(SDL_SHARED TRUE)
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportSDL3)

FUNCTION(ImportSDL2_image)
    set(SDL2IMAGE_VENDORED TRUE)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(FATAL_ERROR "missing SDL_image tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:libsdl-org/SDL_image.git")
    else()
        set(GIT_REPOSITORY "https://github.com/libsdl-org/SDL_image.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportSDL2_image)

FUNCTION(ImportSDL3_image)
    set(SDL3IMAGE_VENDORED TRUE)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(FATAL_ERROR "missing SDL_image tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:libsdl-org/SDL_image.git")
    else()
        set(GIT_REPOSITORY "https://github.com/libsdl-org/SDL_image.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportSDL3_image)

FUNCTION(ImportMbedTLS)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_TAG)
        set(MbedTLS_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(MbedTLS_TAG "2ca6c285a0dd3f33982dd57299012dacab1ff206")
        message(SEND_ERROR "missing MbedTLS TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:Mbed-TLS/mbedtls.git")
    else()
        set(GIT_REPOSITORY "https://github.com/Mbed-TLS/mbedtls.git")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(USE_STATIC_MBEDTLS_LIBRARY TRUE)
    else()
        set(USE_STATIC_MBEDTLS_LIBRARY FALSE)
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(MSVC_STATIC_RUNTIME ON)
    else()
        set(MSVC_STATIC_RUNTIME OFF)
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportMbedTLS)

FUNCTION(ImportGLEW)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_TAG)
        set(GLEW_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(GLEW_TAG "2ca6c285a0dd3f33982dd57299012dacab1ff206")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:nigels-com/glew.git")
    else()
        set(GIT_REPOSITORY "https://github.com/nigels-com/glew.git")
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportGLEW)

FUNCTION(ImportRAPIDFUZZ)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_TAG)
        set(RAPIDFUZZ_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(RAPIDFUZZ_TAG "c6a3ac87c42ddf52f502dc3ed7001c8c2cefb900")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:rapidfuzz/rapidfuzz-cpp.git")
    else()
        set(GIT_REPOSITORY "https://github.com/rapidfuzz/rapidfuzz-cpp.git")
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportRAPIDFUZZ)

FUNCTION(ImportxxHash)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_TAG)
        set(xxHash_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(xxHash_TAG "bbb27a5efb85b92a0486cf361a8635715a53f6ba")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:Cyan4973/xxHash.git")
    else()
        set(GIT_REPOSITORY "https://github.com/Cyan4973/xxHash.git")
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(BUILD_SHARED_LIBS FALSE)
    else()
        set(BUILD_SHARED_LIBS TRUE)
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportxxHash)

FUNCTION(ImportZSTD)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_TAG)
        set(zstd_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(zstd_TAG "f7a8bb1263448e5028aceeba606a08fe3809550f")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:facebook/zstd.git")
    else()
        set(GIT_REPOSITORY "https://github.com/facebook/zstd.git")
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(ZSTD_USE_STATIC_RUNTIME TRUE)
    else()
        set(ZSTD_USE_STATIC_RUNTIME FALSE)
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportZSTD)

FUNCTION(ImportBOOST)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/out)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(BOOST_RUNTIME_LINK "static")
    else()
        set(BOOST_RUNTIME_LINK "shared")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(BUILD_SHARED_LIBS OFF)
    else()
        set(BUILD_SHARED_LIBS ON)
    endif()

    set(DEFAULT_URL https://github.com/boostorg/boost/releases/download/boost-1.87.0/boost-1.87.0-cmake.tar.xz)

    if(IMPORT_PROJECT_URL STREQUAL "")
        set(IMPORT_PROJECT_URL ${DEFAULT_URL})
    elseif(NOT url)
        set(IMPORT_PROJECT_URL ${DEFAULT_URL})
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportBOOST)

FUNCTION(ImportOPENSSL)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/_deps/openssl-src/install)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        set(IMPORT_PROJECT_TAG "98acb6b02839c609ef5b837794e08d906d965335") # 3.4.0
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:openssl/openssl.git")
    else()
        set(GIT_REPOSITORY "https://github.com/openssl/openssl.git")
    endif()

    # cmake_path(GET CMAKE_CURRENT_FUNCTION_LIST_DIR PARENT_PATH OCMAKEUTIL_PATH)
    # cmake_path(NORMAL_PATH OCMAKEUTIL_PATH)
    find_package(ZLIB)

    if(ZLIB_FOUND)
        cmake_path(GET ZLIB_LIBRARY PARENT_PATH ZLIB_LIBRARY_DIR)
    endif()

    if(MSVC)
        find_package(Perl REQUIRED)
        cmake_path(GET PERL_EXECUTABLE PARENT_PATH STRAWBERRY_PERL_PATH)
        cmake_path(GET STRAWBERRY_PERL_PATH PARENT_PATH STRAWBERRY_PERL_PATH)
        cmake_path(GET STRAWBERRY_PERL_PATH PARENT_PATH STRAWBERRY_PERL_PATH)

        include(CMakeDetermineASM_NASMCompiler)

        if(NOT CMAKE_ASM_NASM_COMPILER)
            message(FATAL_ERROR "NASM NOT FOUND")
        endif()

        cmake_path(GET CMAKE_ASM_NASM_COMPILER PARENT_PATH NASM_PATH)
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)

    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportOPENSSL)

FUNCTION(ImportQINIU)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/rundir)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_TAG)
        set(qiniu_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(qiniu_TAG "899f45416943a38c3c1fcd38b85545bf9a4ac647")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:qiniu/c-sdk.git")
    else()
        set(GIT_REPOSITORY "https://github.com/qiniu/c-sdk.git")
    endif()

    find_package(CURL REQUIRED)
    find_package(OpenSSL REQUIRED)

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)

    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportQINIU)

FUNCTION(ImportFOLLY)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    if(IMPORT_PROJECT_TAG)
        set(folly_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(folly_TAG "ba25f8853f8f6697cac2ede73448ab0a1be72be7") # v2025.02.24.00
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:facebook/folly.git")
    else()
        set(GIT_REPOSITORY "https://github.com/facebook/folly.git")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(BUILD_SHARED_LIBS OFF)
    else()
        set(BUILD_SHARED_LIBS ON)
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)

    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportFOLLY)

FUNCTION(ImportTBB)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    if(IMPORT_PROJECT_TAG)
        set(oneTBB_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(oneTBB_TAG "0c0ff192a2304e114bc9e6557582dfba101360ff") # 2022.0.0
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:uxlfoundation/oneTBB.git")
    else()
        set(GIT_REPOSITORY "https://github.com/uxlfoundation/oneTBB.git")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(BUILD_SHARED_LIBS OFF)
    else()
        set(BUILD_SHARED_LIBS ON)
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)

    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportTBB)

FUNCTION(ImportMINIZIP)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(IMPORT_PROJECT_TAG)
        set(MINIZIP_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(MINIZIP_TAG "f3ed731e27a97e30dffe076ed5e0537daae5c1bd") # 4.0.10
        message(SEND_ERROR "missing ZLIB tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:zlib-ng/minizip-ng.git")
    else()
        set(GIT_REPOSITORY "https://github.com/zlib-ng/minizip-ng.git")
    endif()

    find_package(ZLIB)

    if(ZLIB_FOUND)
        set(MZ_ZLIB ON)
    else()
        set(MZ_ZLIB OFF)
    endif()

    find_package(zstd)

    if(zstd_FOUND)
        set(MZ_ZSTD ON)
    else()
        set(MZ_ZSTD OFF)
    endif()

    find_package(BZip2)

    if(BZip2_FOUND)
        set(MZ_BZIP2 ON)
    else()
        set(MZ_BZIP2 OFF)
    endif()

    find_package(LibLZMA)

    if(LibLZMA_FOUND)
        set(MZ_LZMA ON)
    else()
        set(MZ_LZMA OFF)
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportMINIZIP)

FUNCTION(ImportSTEAM)
    FetchContent_Declare(download_steam
        URL ${IMPORT_PROJECT_URL}
        DOWNLOAD_NO_EXTRACT false
        DOWNLOAD_EXTRACT_TIMESTAMP false
    )
    FetchContent_MakeAvailable(download_steam)
    FetchContent_GetProperties(download_steam
        SOURCE_DIR download_steam_SOURCE_DIR
    )
    set(${ProjectName}_INSTALL_DIR ${download_steam_SOURCE_DIR})
    set(${ProjectName}_ROOT ${${ProjectName}_INSTALL_DIR} CACHE STRING "steam root dir")

    if(IMPORT_PROJECT_FIND)
        find_package(${ProjectName} REQUIRED)
    else()
        find_package(${ProjectName})
    endif()
ENDFUNCTION(ImportSTEAM)

FUNCTION(ImportCPUID)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing project tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:anrieff/libcpuid.git")
    else()
        set(GIT_REPOSITORY "https://github.com/anrieff/libcpuid.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Debug
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportCPUID)

FUNCTION(ImportProtobuf)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} CONFIG)

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    find_package(absl CONFIG REQUIRED)

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing project tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:protocolbuffers/protobuf.git")
    else()
        set(GIT_REPOSITORY "https://github.com/protocolbuffers/protobuf.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Debug
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} CONFIG REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportProtobuf)

FUNCTION(ImportLIBWEBSOCKETS)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing project tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:warmcat/libwebsockets.git")
    else()
        set(GIT_REPOSITORY "https://libwebsockets.org/repo/libwebsockets
")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportLIBWEBSOCKETS)

FUNCTION(ImportABSL)
    set(PROJECT_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${PROJECT_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${PROJECT_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing project tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:abseil/abseil-cpp.git")
    else()
        set(GIT_REPOSITORY "https://github.com/abseil/abseil-cpp.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Debug
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${PROJECT_INSTALL_DIR})
ENDFUNCTION(ImportABSL)

FUNCTION(ImportSIMDJSON)
    # simdjson build both static and shared library .
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        set(IMPORT_PROJECT_TAG "0c0ce1bd48baa0677dc7c0945ea7cd1e8b52b297") # 3.13.0
        message(SEND_ERROR "missing simdjson tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:simdjson/simdjson.git")
    else()
        set(GIT_REPOSITORY "https://github.com/simdjson/simdjson.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Debug
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportSIMDJSON)

FUNCTION(ImportRAPIDJSON)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing RapidJSON tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:Tencent/rapidjson.git")
    else()
        set(GIT_REPOSITORY "https://github.com/Tencent/rapidjson.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportRAPIDJSON)

FUNCTION(ImportSQLPP23)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:rbock/sqlpp23.git")
    else()
        set(GIT_REPOSITORY "https://github.com/rbock/sqlpp23.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportSQLPP23)

FUNCTION(ImportDirectXTex)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:microsoft/DirectXTex.git")
    else()
        set(GIT_REPOSITORY "https://github.com/microsoft/DirectXTex.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportDirectXTex)

FUNCTION(ImportCapnProto)
    set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

    if(FindInPath_FOUND)
        AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:capnproto/capnproto.git")
    else()
        set(GIT_REPOSITORY "https://github.com/capnproto/capnproto.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Debug
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
    AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
ENDFUNCTION(ImportCapnProto)