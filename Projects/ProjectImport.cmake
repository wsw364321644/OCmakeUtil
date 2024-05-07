cmake_minimum_required(VERSION 3.24)



FUNCTION(ImportProject ProjectName)
    set(options STATIC_CRT STATIC SSH)
    set(oneValueArgs URL TAG)
    set(multiValueArgs)

    cmake_parse_arguments(IMPORT_PROJECT "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    if(IMPORT_PROJECT_STATIC_CRT)
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_STATIC_CRT")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_STATIC")
    endif()

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_64")
    else()
        set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_32")
    endif()

    string(TOLOWER ${ProjectName} ProjectName_Lower)
    set(WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/external/${ProjectName_Lower}${WORKING_DIRECTORY_SUFFIX})

    list(APPEND CMAKE_GENERATOR_ARGV "-G")
    list(APPEND CMAKE_GENERATOR_ARGV "${CMAKE_GENERATOR}")

    # message(STATUS "CMAKE_GENERATOR_PLATFORM $<$<BOOL:CMAKE_GENERATOR_PLATFORM>:-A ${CMAKE_GENERATOR_PLATFORM}>")
    if(CMAKE_GENERATOR_PLATFORM)
        list(APPEND CMAKE_GENERATOR_ARGV "-A")
        list(APPEND CMAKE_GENERATOR_ARGV "${CMAKE_GENERATOR_PLATFORM}")
    endif()

    if(IMPORT_PROJECT_STATIC)
        if(ProjectName STREQUAL "ZLIB")
            set(ZLIB_USE_STATIC_LIBS "ON")
        elseif(ProjectName STREQUAL "CURL")
            set(CURL_USE_STATIC_LIBS "ON")
        endif()
    endif()

    find_package(${ProjectName})

    if(NOT ${ProjectName}_FOUND)
        if(ProjectName STREQUAL "ZLIB")
            ImportZLIB()
        elseif(ProjectName STREQUAL "CURL")
            ImportCURL()
        elseif(ProjectName STREQUAL "SQLite3")
            ImportSQLITE3()
        elseif(ProjectName STREQUAL "LIBUV")
            ImportLIBUV()
        elseif(ProjectName STREQUAL "Detours")
            ImportDETOURS()
        elseif(ProjectName STREQUAL "SDL2")
            ImportSDL2()
        elseif(ProjectName STREQUAL "MbedTLS")
            ImportMbedTLS()
        else()
            message(STATUS "no project ${ProjectName} to import")
        endif()
    else()
        message(STATUS "Before Import Find ${ProjectName} INCLUDE_DIR :${${ProjectName}_INCLUDE_DIR}")
    endif()
ENDFUNCTION(ImportProject)

FUNCTION(ImportZLIB)
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
        set(GIT_REPOSITORY "git@ssh.github.com:madler/zlib.git")
    else()
        set(GIT_REPOSITORY "https://github.com/madler/zlib.git")
    endif()

    # set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT")
    # set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd")
    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportZLIB)

FUNCTION(ImportCURL)
    if(IMPORT_PROJECT_STATIC_CRT)
        set(CURL_STATIC_CRT ON)
    else()
        set(CURL_STATIC_CRT OFF)
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(BUILD_SHARED_LIBS OFF)
    else()
        set(BUILD_SHARED_LIBS ON)
    endif()

    if(IMPORT_PROJECT_TAG)
        set(CURL_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(CURL_TAG "b16d1fa8ee567b52c09a0f89940b07d8491b881d") # curl-8_0_1
        message(SEND_ERROR "missing CURL tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@ssh.github.com:curl/curl.git")
    else()
        set(GIT_REPOSITORY "https://github.com/curl/curl.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} MODULE REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportCURL)

FUNCTION(ImportSQLITE3)
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

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportSQLITE3)

FUNCTION(ImportLIBUV)
    if(IMPORT_PROJECT_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    if(IMPORT_PROJECT_TAG)
        set(LIBUV_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(LIBUV_TAG "0c1fa696aa502eb749c2c4735005f41ba00a27b8") # v1.44.2
        message(SEND_ERROR "missing LIBUV tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@ssh.github.com:libuv/libuv.git")
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

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportLIBUV)

FUNCTION(ImportDETOURS)
    if(IMPORT_PROJECT_TAG)
        set(DETOURS_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(DETOURS_TAG "4b8c659f549b0ab21cf649377c7a84eb708f5e68")
        message(SEND_ERROR "missing DETOURS tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@ssh.github.com:microsoft/Detours.git")
    else()
        set(GIT_REPOSITORY "https://github.com/microsoft/Detours.git")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix/src/${ProjectName_Lower})
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportDETOURS)


FUNCTION(ImportSDL2)
    if(IMPORT_PROJECT_TAG)
        set(SDL2_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(SDL2_TAG "f461d91cd265d7b9a44b4d472b1df0c0ad2855a0")
        message(SEND_ERROR "missing SDL2 tag")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@ssh.github.com:libsdl-org/SDL.git")
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

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportSDL2)


FUNCTION(ImportMbedTLS)
    if(IMPORT_PROJECT_TAG)
        set(MbedTLS_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(MbedTLS_TAG "2ca6c285a0dd3f33982dd57299012dacab1ff206")
        message(SEND_ERROR "missing MbedTLS TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@ssh.github.com:Mbed-TLS/mbedtls.git")
    else()
        set(GIT_REPOSITORY "https://github.com/Mbed-TLS/mbedtls.git")
    endif()

    if(IMPORT_PROJECT_STATIC)
        set(USE_STATIC_MBEDTLS_LIBRARY TRUE)
    else()
        set(USE_STATIC_MBEDTLS_LIBRARY FALSE)
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

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportMbedTLS)

# MACRO(ADD_DELAYLOAD_FLAGS flagsVar)
# SET(dlls "${ARGN}")
#
# FOREACH(dll ${dlls})
# SET(${flagsVar} "${${flagsVar}} /DELAYLOAD:${dll}.dll")
# ENDFOREACH()
# ENDMACRO()
