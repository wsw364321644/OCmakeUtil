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
    target_include_directories(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${inih_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include/${TARGET_NAME}>
    )
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
    target_include_directories(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${inih_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include/${TARGET_NAME}>
    )
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
    target_include_directories(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${inih_SOURCE_DIR}/cpp>
        $<INSTALL_INTERFACE:include/${TARGET_NAME}>
    )
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
    target_include_directories(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${inih_SOURCE_DIR}/cpp>
        $<INSTALL_INTERFACE:include/${TARGET_NAME}>
    )
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

    find_package(OpenGL)
    find_package(GLUT)
    find_package(GLFW)

    if(OPENGL_FOUND)
        list(APPEND SourceFiles
            ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl2.h
            ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl2.cpp
            ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.h
            ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp
        )

        if(GLUT_FOUND)
            list(APPEND SourceFiles
                ${imgui_SOURCE_DIR}/backends/imgui_impl_glut.h
                ${imgui_SOURCE_DIR}/backends/imgui_impl_glut.cpp
            )
        endif()

        if(GLFW_FOUND)
            list(APPEND SourceFiles
                ${imgui_SOURCE_DIR}/backends/imgui_impl_glfw.h
                ${imgui_SOURCE_DIR}/backends/imgui_impl_glfw.cpp
            )
        endif()
    endif()

    find_package(SDL2)

    if(SDL2_FOUND)
        list(APPEND SourceFiles
            ${imgui_SOURCE_DIR}/backends/imgui_impl_sdl2.h
            ${imgui_SOURCE_DIR}/backends/imgui_impl_sdl2.cpp
        )
    endif()

    if(WIN32)
        list(APPEND SourceFiles
            ${imgui_SOURCE_DIR}/backends/imgui_impl_win32.h
            ${imgui_SOURCE_DIR}/backends/imgui_impl_win32.cpp
            ${imgui_SOURCE_DIR}/backends/imgui_impl_dx9.h
            ${imgui_SOURCE_DIR}/backends/imgui_impl_dx9.cpp
            ${imgui_SOURCE_DIR}/backends/imgui_impl_dx10.h
            ${imgui_SOURCE_DIR}/backends/imgui_impl_dx10.cpp
            ${imgui_SOURCE_DIR}/backends/imgui_impl_dx11.h
            ${imgui_SOURCE_DIR}/backends/imgui_impl_dx11.cpp
            ${imgui_SOURCE_DIR}/backends/imgui_impl_dx12.h
            ${imgui_SOURCE_DIR}/backends/imgui_impl_dx12.cpp
        )
    endif()

    set(TARGET_NAME imgui_a)
    add_library(${TARGET_NAME} STATIC ${SourceFiles})
    target_compile_definitions(${TARGET_NAME} PRIVATE -DImTextureID=ImU64)
    TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${imgui_SOURCE_DIR}/backends>
        $<BUILD_INTERFACE:${imgui_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include/${TARGET_NAME}>
    )

    if(SDL2_FOUND)
        target_link_libraries(${TARGET_NAME} PRIVATE SDL2::SDL2-static)
    endif()

    if(OPENGL_FOUND)
        target_link_libraries(${TARGET_NAME} PRIVATE OpenGL::GL)

        if(GLUT_FOUND)
            target_link_libraries(${TARGET_NAME} PRIVATE GLUT::GLUT)
        endif()

        if(GLFW_FOUND)
            target_link_libraries(${TARGET_NAME} PRIVATE GLFW::GLFW)
        endif()
    endif()
ENDFUNCTION(Importimgui)
