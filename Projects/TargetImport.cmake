cmake_minimum_required(VERSION 3.24)
include(FetchContent)
include(GNUInstallDirs)
include(RegexHelper)

FUNCTION(ImportTarget TargetName)
    set(options STATIC SSH)
    set(oneValueArgs URL TAG)
    set(multiValueArgs)

    cmake_parse_arguments(IMPORT_PROJECT "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    if(IMPORT_PROJECT_TAG)
        IsSHA1String(IMPORT_PROJECT_TAG BGIT_TAG_SHA1)

        if(BGIT_TAG_SHA1)
            set(GIT_SHALLOW_VAL FALSE)
        else()
            set(GIT_SHALLOW_VAL TRUE)
        endif()
    endif()

    if(TargetName STREQUAL "inih")
        Importinih()
    elseif(TargetName STREQUAL "imgui")
        Importimgui()
    elseif(TargetName STREQUAL "mpack")
        Importmpack()
    elseif(TargetName STREQUAL "rollinghashcpp")
        Importrollinghashcpp()
    elseif(TargetName STREQUAL "better-enums")
        Importbetterenums()
    elseif(TargetName STREQUAL "ValveFileVDF")
        ImportValveFileVDF()
    elseif(TargetName STREQUAL "RapidJSON")
        ImportRapidJSON()
    else()
        message(STATUS "no target ${TargetName} to import")
    endif()
ENDFUNCTION(ImportTarget)

FUNCTION(Importinih)
    set(TARGET_NAME inih)

    if(TARGET ${TARGET_NAME})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        set(IMPORT_PROJECT_TAG "5cc5e2c24642513aaa5b19126aad42d0e4e0923e") # r58
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:benhoyt/inih.git")
    else()
        set(GIT_REPOSITORY "https://github.com/benhoyt/inih.git")
    endif()

    FetchContent_Declare(
        inih
        GIT_REPOSITORY ${GIT_REPOSITORY}
        GIT_TAG ${IMPORT_PROJECT_TAG}
        GIT_SHALLOW ${GIT_SHALLOW_VAL}
    )
    FetchContent_MakeAvailable(inih)
    FetchContent_GetProperties(inih)

    set(SourceFiles "")
    list(APPEND SourceFiles
        ${inih_SOURCE_DIR}/ini.c
    )

    function(add_inih TARGET_NAME)
        target_sources(
            ${TARGET_NAME}
            PRIVATE
            ${SourceFiles}
            PUBLIC
            FILE_SET HEADERS
            BASE_DIRS ${inih_SOURCE_DIR}
            FILES
            $<BUILD_INTERFACE:${inih_SOURCE_DIR}/ini.h>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/ini.h>
        )
        install(TARGETS ${TARGET_NAME}
            EXPORT ${TARGET_NAME}Targets
            LIBRARY DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}
            ARCHIVE DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_BINDIR}
            PUBLIC_HEADER DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_INCLUDEDIR}
            FILE_SET HEADERS
            DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_INCLUDEDIR}
        )

        install(EXPORT ${TARGET_NAME}Targets
            FILE ${TARGET_NAME}Targets.cmake
            NAMESPACE inih::
            DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}
        )
    endfunction()

    add_library(${TARGET_NAME} SHARED)
    target_compile_definitions(${TARGET_NAME} PUBLIC -DINI_SHARED_LIB)
    target_compile_definitions(${TARGET_NAME} PRIVATE -DINI_SHARED_LIB_BUILDING)
    set_target_properties(${TARGET_NAME} PROPERTIES CXX_STANDARD_REQUIRED OFF)
    set_target_properties(${TARGET_NAME} PROPERTIES LINKER_LANGUAGE C)
    add_inih(${TARGET_NAME})

    set(TARGET_NAME ${TARGET_NAME}_a)
    add_library(${TARGET_NAME} STATIC)
    set_target_properties(${TARGET_NAME} PROPERTIES CXX_STANDARD_REQUIRED OFF)
    set_target_properties(${TARGET_NAME} PROPERTIES LINKER_LANGUAGE C)
    add_inih(${TARGET_NAME})

    list(APPEND SourceFiles
        ${inih_SOURCE_DIR}/cpp/INIReader.cpp
    )

    function(add_inihpp TARGET_NAME)
        target_sources(
            ${TARGET_NAME}
            PRIVATE
            ${SourceFiles}
            PUBLIC
            FILE_SET HEADERS
            BASE_DIRS ${inih_SOURCE_DIR}
            FILES
            $<BUILD_INTERFACE:${inih_SOURCE_DIR}/ini.h>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/ini.h>
            $<BUILD_INTERFACE:${inih_SOURCE_DIR}/cpp/INIReader.h>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/cpp/INIReader.h>
        )
        install(TARGETS ${TARGET_NAME}
            EXPORT ${TARGET_NAME}Targets
            LIBRARY DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}
            ARCHIVE DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_BINDIR}
            PUBLIC_HEADER DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_INCLUDEDIR}
            FILE_SET HEADERS
            DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_INCLUDEDIR}
        )

        install(EXPORT ${TARGET_NAME}Targets
            FILE ${TARGET_NAME}Targets.cmake
            NAMESPACE inih::
            DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}
        )
    endfunction()

    set(TARGET_NAME inihpp)
    add_library(${TARGET_NAME} SHARED)
    target_compile_definitions(${TARGET_NAME} PUBLIC -DINI_SHARED_LIB)
    target_compile_definitions(${TARGET_NAME} PRIVATE -DINI_SHARED_LIB_BUILDING)
    add_inihpp(${TARGET_NAME})

    set(TARGET_NAME ${TARGET_NAME}_a)
    add_library(${TARGET_NAME} STATIC)
    add_inihpp(${TARGET_NAME})
ENDFUNCTION(Importinih)

FUNCTION(Importimgui)
    set(TARGET_NAME imgui_a)

    if(TARGET ${TARGET_NAME})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        set(IMPORT_PROJECT_TAG "6ccc561a2ab497ad4ae6ee1dbd3b992ffada35cb") # v1.90.6
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:ocornut/imgui.git")
    else()
        set(GIT_REPOSITORY "https://github.com/ocornut/imgui.git")
    endif()

    FetchContent_Declare(
        imgui
        GIT_REPOSITORY ${GIT_REPOSITORY}
        GIT_TAG ${IMPORT_PROJECT_TAG}
        GIT_SHALLOW ${GIT_SHALLOW_VAL}
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
    target_compile_definitions(${TARGET_NAME} PUBLIC -DImTextureID=ImU64)
    target_compile_definitions(${TARGET_NAME} PUBLIC -DIMGUI_USE_WCHAR32)

    TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${imgui_SOURCE_DIR}/backends>
        $<BUILD_INTERFACE:${imgui_SOURCE_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${TARGET_NAME}>
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

FUNCTION(Importmpack)
    set(TARGET_NAME mpack)

    if(TARGET ${TARGET_NAME})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        set(IMPORT_PROJECT_TAG "79d3fcd3e04338b06e82d01a62f4aa98c7bad5f7") # v1.1.1
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:ludocode/mpack.git")
    else()
        set(GIT_REPOSITORY "https://github.com/ludocode/mpack.git")
    endif()

    FetchContent_Declare(
        mpack
        GIT_REPOSITORY ${GIT_REPOSITORY}
        GIT_TAG ${IMPORT_PROJECT_TAG}
        GIT_SHALLOW ${GIT_SHALLOW_VAL}
    )
    FetchContent_MakeAvailable(mpack)
    FetchContent_GetProperties(mpack)

    set(SourceFiles "")
    set(HeaderFiles "")

    list(APPEND HeaderFiles
        ${mpack_SOURCE_DIR}/src/mpack/mpack-common.h
        ${mpack_SOURCE_DIR}/src/mpack/mpack-expect.h
        ${mpack_SOURCE_DIR}/src/mpack/mpack-node.h
        ${mpack_SOURCE_DIR}/src/mpack/mpack-platform.h
        ${mpack_SOURCE_DIR}/src/mpack/mpack-reader.h
        ${mpack_SOURCE_DIR}/src/mpack/mpack-writer.h
        ${mpack_SOURCE_DIR}/src/mpack/mpack.h
    )

    list(APPEND SourceFiles
        ${mpack_SOURCE_DIR}/src/mpack/mpack-common.c
        ${mpack_SOURCE_DIR}/src/mpack/mpack-expect.c
        ${mpack_SOURCE_DIR}/src/mpack/mpack-node.c
        ${mpack_SOURCE_DIR}/src/mpack/mpack-platform.c
        ${mpack_SOURCE_DIR}/src/mpack/mpack-reader.c
        ${mpack_SOURCE_DIR}/src/mpack/mpack-writer.c
    )

    add_library(${TARGET_NAME} SHARED)
    target_sources(
        ${TARGET_NAME}
        PRIVATE
        ${SourceFiles}
        PUBLIC
        ${HeaderFiles}
    )
    target_include_directories(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${mpack_SOURCE_DIR}/src>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${TARGET_NAME}>
    )
    set_target_properties(${TARGET_NAME} PROPERTIES CXX_STANDARD_REQUIRED OFF)
    set_target_properties(${TARGET_NAME} PROPERTIES LINKER_LANGUAGE C)

    set(TARGET_NAME ${TARGET_NAME}_a)
    add_library(${TARGET_NAME} STATIC)
    target_sources(
        ${TARGET_NAME}
        PRIVATE
        ${SourceFiles}
        PUBLIC
        ${HeaderFiles}
    )
    target_include_directories(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${mpack_SOURCE_DIR}/src>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${TARGET_NAME}>
    )
    set_target_properties(${TARGET_NAME} PROPERTIES CXX_STANDARD_REQUIRED OFF)
    set_target_properties(${TARGET_NAME} PROPERTIES LINKER_LANGUAGE C)
ENDFUNCTION(Importmpack)

FUNCTION(Importrollinghashcpp)
    set(TARGET_NAME rollinghashcpp)

    if(TARGET ${TARGET_NAME})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        set(IMPORT_PROJECT_TAG "5cb883b8692f56636835697863ddb80cc8ef2311")
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:lemire/rollinghashcpp.git")
    else()
        set(GIT_REPOSITORY "https://github.com/lemire/rollinghashcpp.git")
    endif()

    FetchContent_Declare(
        rollinghashcpp_git
        GIT_REPOSITORY ${GIT_REPOSITORY}
        GIT_TAG ${IMPORT_PROJECT_TAG}
        GIT_SHALLOW ${GIT_SHALLOW_VAL}
    )
    FetchContent_Populate(rollinghashcpp_git)
    FetchContent_GetProperties(rollinghashcpp_git)

    NewTargetSource()
    AddSourceFolder(RECURSE INTERFACE "${rollinghashcpp_git_SOURCE_DIR}/include")
    source_group(TREE ${rollinghashcpp_git_SOURCE_DIR} FILES ${SourceFiles})

    add_library(${TARGET_NAME} INTERFACE ${SourceFiles})

    AddTargetInclude(${TARGET_NAME})
    AddTargetInstall(${TARGET_NAME} rollinghashcpp)
ENDFUNCTION(Importrollinghashcpp)

FUNCTION(Importbetterenums)
    set(TARGET_NAME better-enums)

    if(TARGET ${TARGET_NAME})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        set(IMPORT_PROJECT_TAG "520d8ee39037c9c94aa6e708a4fd6c0fa313ae80")
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:aantron/better-enums.git")
    else()
        set(GIT_REPOSITORY "https://github.com/aantron/better-enums.git")
    endif()

    FetchContent_Declare(
        ${TARGET_NAME}
        GIT_REPOSITORY ${GIT_REPOSITORY}
        GIT_TAG ${IMPORT_PROJECT_TAG}
        GIT_SHALLOW ${GIT_SHALLOW_VAL}
    )
    FetchContent_MakeAvailable(${TARGET_NAME})
    FetchContent_GetProperties(${TARGET_NAME})

    set(SourceFiles "")
    set(HeaderFiles "")

    list(APPEND HeaderFiles
        ${${TARGET_NAME}_SOURCE_DIR}/enum.h
    )

    add_library(${TARGET_NAME} INTERFACE)
    target_sources(
        ${TARGET_NAME}
        PUBLIC
        ${HeaderFiles}
    )
    target_include_directories(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${${TARGET_NAME}_SOURCE_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${TARGET_NAME}>
    )
    set_target_properties(${TARGET_NAME} PROPERTIES CXX_STANDARD_REQUIRED OFF)
    set_target_properties(${TARGET_NAME} PROPERTIES LINKER_LANGUAGE C)
ENDFUNCTION(Importbetterenums)

FUNCTION(ImportValveFileVDF)
    set(TARGET_NAME ValveFileVDF)

    if(TARGET ${TARGET_NAME})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:TinyTinni/ValveFileVDF.git")
    else()
        set(GIT_REPOSITORY "https://github.com/TinyTinni/ValveFileVDF.git")
    endif()

    string(TOLOWER "${TARGET_NAME}_git" TargetGitName)
    FetchContent_Declare(
        ${TargetGitName}
        GIT_REPOSITORY ${GIT_REPOSITORY}
        GIT_TAG ${IMPORT_PROJECT_TAG}
        GIT_SHALLOW ${GIT_SHALLOW_VAL}
    )
    FetchContent_Populate(${TargetGitName})
    FetchContent_GetProperties(${TargetGitName})
    NewTargetSource()
    AddSourceFolder(INCLUDE RECURSE PUBLIC "${${TargetGitName}_SOURCE_DIR}/include")
    add_library(${TARGET_NAME} INTERFACE)
    AddTargetInclude(${TARGET_NAME})
    AddTargetInstall(${TARGET_NAME} ${TARGET_NAME})
ENDFUNCTION(ImportValveFileVDF)

FUNCTION(ImportRapidJSON)
    if(TARGET ${TargetName})
        return()
    endif()

    if(NOT IMPORT_PROJECT_TAG)
        message(SEND_ERROR "missing PROJECT_TAG")
    endif()

    if(IMPORT_PROJECT_SSH)
        set(GIT_REPOSITORY "git@github.com:Tencent/rapidjson.git")
    else()
        set(GIT_REPOSITORY "https://github.com/Tencent/rapidjson.git")
    endif()

    string(TOLOWER "${TargetName}_git" TargetGitName)
    FetchContent_Declare(
        ${TargetGitName}
        GIT_REPOSITORY ${GIT_REPOSITORY}
        GIT_TAG ${IMPORT_PROJECT_TAG}
        GIT_SHALLOW ${GIT_SHALLOW_VAL}
        GIT_SUBMODULES ""
    )
    FetchContent_Populate(${TargetGitName})
    FetchContent_GetProperties(${TargetGitName})
    NewTargetSource()
    AddSourceFolder(INCLUDE RECURSE PUBLIC "${${TargetGitName}_SOURCE_DIR}/include")
    add_library(${TargetName} INTERFACE)
    AddTargetInclude(${TargetName})
    AddTargetInstall(${TargetName} ${TargetName})
ENDFUNCTION(ImportRapidJSON)