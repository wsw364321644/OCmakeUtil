cmake_minimum_required(VERSION 3.20)

FUNCTION(ImportZLIB)
    set(WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/external/zlib)
    find_package(ZLIB)

    if(NOT ZLIB_FOUND)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/zlib.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt)
        execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
            WORKING_DIRECTORY ${WORKING_DIRECTORY})
        execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
            WORKING_DIRECTORY ${WORKING_DIRECTORY})
        

        list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/zlib-prefix)
        find_package(ZLIB REQUIRED)
        set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE FORCE "")
    endif()
ENDFUNCTION(ImportZLIB)

FUNCTION(ImportCURL)
    ImportZLIB()
    set(WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/external/curl)
    find_package(CURL)
    message(STATUS "CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH}")

    if(NOT CURL_FOUND)
        configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/curl.txt.in ${WORKING_DIRECTORY}/CMakeLists.txt)
        execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
            WORKING_DIRECTORY ${WORKING_DIRECTORY})
        execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release
            WORKING_DIRECTORY ${WORKING_DIRECTORY})
        

        list(APPEND CMAKE_PREFIX_PATH ${WORKING_DIRECTORY}/curl-prefix)
        find_package(CURL REQUIRED)
        set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
    endif()
ENDFUNCTION(ImportCURL)

# MACRO(ADD_DELAYLOAD_FLAGS flagsVar)
# SET(dlls "${ARGN}")
#
# FOREACH(dll ${dlls})
# SET(${flagsVar} "${${flagsVar}} /DELAYLOAD:${dll}.dll")
# ENDFOREACH()
# ENDMACRO()
