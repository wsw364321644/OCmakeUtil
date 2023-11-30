cmake_minimum_required(VERSION 3.20)

FUNCTION(ImportProject ProjectName)
    set(options STATIC_CRT STATIC)
    set(oneValueArgs URL TAG)
    set(multiValueArgs)

    cmake_parse_arguments(IMPORT_PROJECT "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    string(TOLOWER ${ProjectName} ProjectName_Lower)
    set(WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/external/${ProjectName_Lower})

    list(APPEND CMAKE_GENERATOR_ARGV "-G")
    list(APPEND CMAKE_GENERATOR_ARGV "${CMAKE_GENERATOR}")

    # message(STATUS "CMAKE_GENERATOR_PLATFORM $<$<BOOL:CMAKE_GENERATOR_PLATFORM>:-A ${CMAKE_GENERATOR_PLATFORM}>")
    if(CMAKE_GENERATOR_PLATFORM)
        list(APPEND CMAKE_GENERATOR_ARGV "-A")
        list(APPEND CMAKE_GENERATOR_ARGV "${CMAKE_GENERATOR_PLATFORM}")
    endif()

    if(ProjectName STREQUAL "ZLIB" AND IMPORT_PROJECT_STATIC)
        set(ZLIB_USE_STATIC_LIBS "ON")
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
        else()
            message(STATUS "no project ${ProjectName} to import")
        endif()
    else()
        message(STATUS "ImportProject Find ${ProjectName} INCLUDE_DIR :${${ProjectName}_INCLUDE_DIR}")
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

    # set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT")
    # set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd")
    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE FORCE "")
ENDFUNCTION(ImportZLIB)

FUNCTION(ImportCURL)
    if(IMPORT_PROJECT_STATIC_CRT)
        set(CURL_STATIC_CRT ON)
    else()
        set(CURL_STATIC_CRT OFF)
    endif()

    if(IMPORT_PROJECT_TAG)
        set(CURL_TAG ${IMPORT_PROJECT_TAG})
    else()
        set(CURL_TAG "b16d1fa8ee567b52c09a0f89940b07d8491b881d") # curl-8_0_1
        message(SEND_ERROR "missing CURL tag")
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
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

    # set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT")
    # set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd")
    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt @ONLY)
    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE FORCE "")
ENDFUNCTION(ImportLIBUV)

# MACRO(ADD_DELAYLOAD_FLAGS flagsVar)
# SET(dlls "${ARGN}")
#
# FOREACH(dll ${dlls})
# SET(${flagsVar} "${${flagsVar}} /DELAYLOAD:${dll}.dll")
# ENDFOREACH()
# ENDMACRO()
