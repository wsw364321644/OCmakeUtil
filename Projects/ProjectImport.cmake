cmake_minimum_required(VERSION 3.20)

FUNCTION(ImportProject ProjectName)
    set(options STARIC_CRT)
    set(oneValueArgs)
    set(multiValueArgs)

    cmake_parse_arguments(IMPORT_PROJECT "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    string(TOLOWER ${ProjectName} ProjectName_Lower)
    set(WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/external/${ProjectName_Lower})
    find_package(${ProjectName})

    if(NOT ${ProjectName}_FOUND)
        if(ProjectName STREQUAL "ZLIB")
            ImportZLIB()
        elseif(ProjectName STREQUAL "CURL")
            ImportCURL()
        else()
            message(STATUS "no project to import")
        endif()
    endif()
ENDFUNCTION(ImportProject)

FUNCTION(ImportZLIB)

    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    #set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT")
    #set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd")


    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt)
    execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}"  -A ${CMAKE_GENERATOR_PLATFORM} .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE FORCE "")
ENDFUNCTION(ImportZLIB)

FUNCTION(ImportCURL)
    if(IMPORT_PROJECT_STARIC_CRT)
        set(CURL_STATIC_CRT ON)
    else()
        set(CURL_STATIC_CRT OFF)
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt)
    execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
        WORKING_DIRECTORY ${WORKING_DIRECTORY})
    execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
        WORKING_DIRECTORY ${WORKING_DIRECTORY})

    list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix)
    find_package(${ProjectName} REQUIRED)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
ENDFUNCTION(ImportCURL)

# MACRO(ADD_DELAYLOAD_FLAGS flagsVar)
# SET(dlls "${ARGN}")
#
# FOREACH(dll ${dlls})
# SET(${flagsVar} "${${flagsVar}} /DELAYLOAD:${dll}.dll")
# ENDFOREACH()
# ENDMACRO()
