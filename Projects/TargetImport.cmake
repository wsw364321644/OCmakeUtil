cmake_minimum_required(VERSION 3.24)

FUNCTION(ImportTarget TargetName)
    set(options STATIC SSH)
    set(oneValueArgs URL TAG)
    set(multiValueArgs)

    cmake_parse_arguments(IMPORT_PROJECT "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    if(TargetName STREQUAL "inih")
        Importinih()
    elseif(TargetName STREQUAL "imgui")
        Importimgui()
    else()
        message(STATUS "no target ${TargetName} to import")
    endif()

ENDFUNCTION(ImportTarget)

FUNCTION(Importinih)
    if(NOT IMPORT_PROJECT_TAG)
        set(IMPORT_PROJECT_TAG "5cc5e2c24642513aaa5b19126aad42d0e4e0923e") # r58
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@ssh.github.com:benhoyt/inih.git")
    else()
        set(GIT_REPOSITORY "https://github.com/benhoyt/inih.git")
    endif()

    FetchContent_Declare(
        inih
        GIT_REPOSITORY ${GIT_REPOSITORY}
        GIT_TAG ${IMPORT_PROJECT_TAG}
    )
    FetchContent_MakeAvailable(inih)
    FetchContent_GetProperties(inih)

    set(TARGET_NAME inih)
    add_library(${TARGET_NAME} SHARED)
    target_sources(
        ${TARGET_NAME}
        PRIVATE
        ${inih_SOURCE_DIR}/ini.h
        ${inih_SOURCE_DIR}/ini.c
    )
    target_include_directories(${TARGET_NAME} PUBLIC ${PROJECT_SOURCE_DIR})
    target_compile_definitions(${TARGET_NAME} PUBLIC -DINI_SHARED_LIB)
    target_compile_definitions(${TARGET_NAME} PRIVATE -DINI_SHARED_LIB_BUILDING)
    set_target_properties(${TARGET_NAME} PROPERTIES CXX_STANDARD_REQUIRED OFF)
    set_target_properties(${TARGET_NAME} PROPERTIES LINKER_LANGUAGE C)

    set(TARGET_NAME ${TARGET_NAME}_a)
    add_library(${TARGET_NAME} STATIC)
    target_sources(
        ${TARGET_NAME}
        PRIVATE
        ${inih_SOURCE_DIR}/ini.h
        ${inih_SOURCE_DIR}/ini.c
    )
    target_include_directories(${TARGET_NAME} PUBLIC ${PROJECT_SOURCE_DIR})
    set_target_properties(${TARGET_NAME} PROPERTIES CXX_STANDARD_REQUIRED OFF)
    set_target_properties(${TARGET_NAME} PROPERTIES LINKER_LANGUAGE C)

    set(TARGET_NAME inihpp)
    add_library(${TARGET_NAME} SHARED)
    target_sources(
        ${TARGET_NAME}
        PRIVATE
        ${inih_SOURCE_DIR}/ini.h
        ${inih_SOURCE_DIR}/ini.c
        ${inih_SOURCE_DIR}/cpp/INIReader.cpp
        ${inih_SOURCE_DIR}/cpp/INIReader.h
    )
    target_include_directories(${TARGET_NAME} PUBLIC ${PROJECT_SOURCE_DIR}/cpp)
    target_compile_definitions(${TARGET_NAME} PUBLIC -DINI_SHARED_LIB)
    target_compile_definitions(${TARGET_NAME} PRIVATE -DINI_SHARED_LIB_BUILDING)

    set(TARGET_NAME ${TARGET_NAME}_a)
    add_library(${TARGET_NAME} STATIC)
    target_sources(
        ${TARGET_NAME}
        PRIVATE
        ${inih_SOURCE_DIR}/ini.h
        ${inih_SOURCE_DIR}/ini.c
        ${inih_SOURCE_DIR}/cpp/INIReader.cpp
        ${inih_SOURCE_DIR}/cpp/INIReader.h
    )
    target_include_directories(${TARGET_NAME} PUBLIC ${PROJECT_SOURCE_DIR}/cpp)
ENDFUNCTION(Importinih)

FUNCTION(Importimgui)
    if(NOT IMPORT_PROJECT_TAG)
        set(IMPORT_PROJECT_TAG "6ccc561a2ab497ad4ae6ee1dbd3b992ffada35cb") # v1.90.6
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@ssh.github.com:ocornut/imgui.git")
    else()
        set(GIT_REPOSITORY "https://github.com/ocornut/imgui.git")
    endif()

    FetchContent_Declare(
        imgui
        GIT_REPOSITORY ${GIT_REPOSITORY}
        GIT_TAG ${IMPORT_PROJECT_TAG}
    )
    FetchContent_MakeAvailable(imgui)
    FetchContent_GetProperties(imgui)

    set(SourceFiles "")
    set(HeaderFiles "")

    list(APPEND SourceFiles
        ${imgui_SOURCE_DIR}/imgui.h
        ${imgui_SOURCE_DIR}/imgui.cpp
        ${imgui_SOURCE_DIR}/imconfig.h
        ${imgui_SOURCE_DIR}/imgui_draw.cpp
        ${imgui_SOURCE_DIR}/imgui_internal.h
        ${imgui_SOURCE_DIR}/imgui_widgets.cpp
        ${imgui_SOURCE_DIR}/imgui_tables.cpp
        ${imgui_SOURCE_DIR}/imgui_demo.cpp
    )
    if(WIN32)
        list(APPEND SourceFiles
            ${imgui_SOURCE_DIR}/backends/imgui_impl_win32.h
            ${imgui_SOURCE_DIR}/backends/imgui_impl_win32.cpp
        )
    endif()

    set(TARGET_NAME imgui_a)
    add_library(${TARGET_NAME} STATIC ${SourceFiles})
    TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} PUBLIC 
    ${imgui_SOURCE_DIR}/backends
    ${imgui_SOURCE_DIR}
    )
ENDFUNCTION(Importimgui)
