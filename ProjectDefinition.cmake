cmake_minimum_required(VERSION 3.20)
include(GNUInstallDirs)

if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    set(CMAKE_LINK_LIBRARY_USING_delayload "/DELAYLOAD:\"<LIBRARY>\"" PARENT_SCOPE)
    set(CMAKE_LINK_LIBRARY_USING_delayload_SUPPORTED TRUE PARENT_SCOPE)
endif()

FUNCTION(TargetAddDelayLoad _TargetName _DllName)
    get_filename_component(FILE_SUFFIX "${_DllName}" EXT)

    if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
        target_link_libraries(${_TargetName} PRIVATE delayimp)

        if(FILE_SUFFIX MATCHES ".dll")
            target_link_options(${_TargetName} PRIVATE "/DELAYLOAD:${_DllName}")
        else()
            target_link_options(${_TargetName} PRIVATE "/DELAYLOAD:${_DllName}.dll")
        endif()
    endif()
ENDFUNCTION(TargetAddDelayLoad)

FUNCTION(EXCLUDE_FILES_FROM_DIR_IN_LIST _InFileList _excludeDirName)
    foreach(ITR ${_InFileList})
        if("${ITR}" MATCHES "(.*)${_excludeDirName}(.*)") # Check if the item matches the directory name in _excludeDirName
            list(REMOVE_ITEM _InFileList ${ITR}) # Remove the item from the list
        endif("${ITR}" MATCHES "(.*)${_excludeDirName}(.*)")
    endforeach(ITR)

    set(EXCLUDED_FILES ${_InFileList} PARENT_SCOPE) # Return the SOURCE_FILES variable to the calling parent
ENDFUNCTION(EXCLUDE_FILES_FROM_DIR_IN_LIST)

macro(ExcludeFile FileListVar)
    if(WIN32)
        EXCLUDE_FILES_FROM_DIR_IN_LIST("${${FileListVar}}" "Linux")
        EXCLUDE_FILES_FROM_DIR_IN_LIST("${${FileListVar}}" "linux")
    elseif(UNIX)
        EXCLUDE_FILES_FROM_DIR_IN_LIST("${${FileListVar}}" "Windows")
        EXCLUDE_FILES_FROM_DIR_IN_LIST("${${FileListVar}}" "windows")
    endif()

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        EXCLUDE_FILES_FROM_DIR_IN_LIST("${EXCLUDED_FILES}" "X86")
        EXCLUDE_FILES_FROM_DIR_IN_LIST("${EXCLUDED_FILES}" "x86")
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
        EXCLUDE_FILES_FROM_DIR_IN_LIST("${EXCLUDED_FILES}" "X64")
        EXCLUDE_FILES_FROM_DIR_IN_LIST("${EXCLUDED_FILES}" "x64")
    endif()

    set(${FileListVar} ${EXCLUDED_FILES})
endmacro(ExcludeFile)

macro(SearchSourceFiles FolderPath bRecurse)
    set(temppath ${FolderPath})
    cmake_path(APPEND temppath "*.h" OUTPUT_VARIABLE TmpHHeader)
    cmake_path(APPEND temppath "*.hpp" OUTPUT_VARIABLE TmpHppHeader)
    cmake_path(APPEND temppath "*.c" OUTPUT_VARIABLE TmpC)
    cmake_path(APPEND temppath "*.cc" OUTPUT_VARIABLE TmpCC)
    cmake_path(APPEND temppath "*.cpp" OUTPUT_VARIABLE TmpCpp)
    cmake_path(APPEND temppath "*.s" OUTPUT_VARIABLE TmpS)
    cmake_path(APPEND temppath "*.asm" OUTPUT_VARIABLE TmpAsm)
    cmake_path(APPEND temppath "*.ico" OUTPUT_VARIABLE TmpIcon)
    cmake_path(APPEND temppath "*.rc" OUTPUT_VARIABLE TmpRC)

    cmake_path(APPEND temppath "*.config" OUTPUT_VARIABLE TmpConfig)
    cmake_path(APPEND temppath "*.xaml" OUTPUT_VARIABLE TmpXAML)
    cmake_path(APPEND temppath "*.cs" OUTPUT_VARIABLE TmpCS)
    cmake_path(APPEND temppath "*.resx" OUTPUT_VARIABLE TmpRESX)
    cmake_path(APPEND temppath "*.settings" OUTPUT_VARIABLE TmpSettings)

    if(${bRecurse})
        set(SearchParam_RECURSE GLOB_RECURSE)
    else()
        set(SearchParam_RECURSE GLOB)
    endif()

    file(${SearchParam_RECURSE} TmpHeader LIST_DIRECTORIES false CONFIGURE_DEPENDS ${TmpHHeader} ${TmpHppHeader})
    file(${SearchParam_RECURSE} TmpSource LIST_DIRECTORIES false CONFIGURE_DEPENDS ${TmpC} ${TmpCC} ${TmpCpp} ${TmpIcon} ${TmpRC})
    file(${SearchParam_RECURSE} TmpAsmSource LIST_DIRECTORIES false CONFIGURE_DEPENDS ${TmpS} ${TmpAsm})
    ExcludeFile(TmpAsmSource)
    ExcludeFile(TmpHeader)
    ExcludeFile(TmpSource)
    set_property(SOURCE TmpAsmSource APPEND PROPERTY COMPILE_OPTIONS "-x" "assembler-with-cpp")
    list(APPEND TmpSource ${TmpAsmSource})

    # message(STATUS "EXCLUDED_FILES ${EXCLUDED_FILES}")
    # if(NOT EXCLUDED_FILES STREQUAL "")
    # set(SourceFiles "${SourceFiles};${EXCLUDED_FILES}")
    # endif()
endmacro(SearchSourceFiles)

macro(AddSourceFolder)
    set(options INCLUDE RECURSE)
    set(oneValueArgs)
    set(multiValueArgs PUBLIC PRIVATE INTERFACE)
    cmake_parse_arguments(AddSourceFolder "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    foreach(SourceFolder ${AddSourceFolder_PRIVATE})
        # list(LENGTH PrivateIncludeFolders FoldersLength)
        list(APPEND PrivateIncludeFolders ${SourceFolder})
        SearchSourceFiles(${SourceFolder} ${AddSourceFolder_RECURSE})
        list(APPEND SourceFiles ${TmpHeader} ${TmpSource})
        list(APPEND PrivateFiles ${TmpHeader})

        # set("PrivateFiles${FoldersLength}" "")
        # list(APPEND "PrivateFiles${FoldersLength}" ${TmpHeader} ${TmpSource})
    endforeach()

    foreach(SourceFolder ${AddSourceFolder_UNPARSED_ARGUMENTS})
        # list(LENGTH PrivateIncludeFolders FoldersLength)
        list(APPEND PrivateIncludeFolders ${SourceFolder})
        SearchSourceFiles(${SourceFolder} ${AddSourceFolder_RECURSE})
        list(APPEND SourceFiles ${TmpHeader} ${TmpSource})
        list(APPEND PrivateFiles ${TmpHeader} ${TmpSource})

        # set("PrivateFiles${FoldersLength}" "")
        # list(APPEND "PrivateFiles${FoldersLength}" ${TmpHeader} ${TmpSource})
    endforeach()

    foreach(SourceFolder ${AddSourceFolder_PUBLIC})
        # list(LENGTH PublicIncludeFolders FoldersLength)
        list(APPEND PublicIncludeFolders ${SourceFolder})
        SearchSourceFiles(${SourceFolder} ${AddSourceFolder_RECURSE})

        if(AddSourceFolder_INCLUDE)
            list(APPEND SourceFiles ${TmpHeader})
        else()
            list(APPEND SourceFiles ${TmpHeader} ${TmpSource})
            list(APPEND PrivateFiles ${TmpSource})
        endif()

        foreach(FILE ${TmpHeader})
            cmake_path(
                RELATIVE_PATH FILE
                BASE_DIRECTORY ${SourceFolder}
                OUTPUT_VARIABLE IncludeFileRelativePath
            )
            cmake_path(APPEND "@TARGET_NAME_TOKEN@" ${CMAKE_INSTALL_INCLUDEDIR} ${IncludeFileRelativePath} OUTPUT_VARIABLE IncludeFileInstallPath)
            list(APPEND PublicIncludeFiles "$<BUILD_INTERFACE:${FILE}>")
            list(APPEND PublicIncludeFiles "$<INSTALL_INTERFACE:${IncludeFileInstallPath}>")
        endforeach()

        # set("PublicIncludeFiles${FoldersLength}" "")
        # list(APPEND "PublicIncludeFiles${FoldersLength}" ${TmpHeader})
    endforeach()

    foreach(SourceFolder ${AddSourceFolder_INTERFACE})
        # list(LENGTH InterfaceIncludeFolders FoldersLength)
        list(APPEND InterfaceIncludeFolders ${SourceFolder})
        SearchSourceFiles(${SourceFolder} ${AddSourceFolder_RECURSE} TRUE)

        if(AddSourceFolder_INCLUDE)
            list(APPEND SourceFiles ${TmpHeader})
        else()
            list(APPEND SourceFiles ${TmpHeader} ${TmpSource})
            list(APPEND PrivateFiles ${TmpSource})
        endif()

        foreach(FILE ${TmpHeader})
            cmake_path(RELATIVE_PATH FILE
                BASE_DIRECTORY ${SourceFolder}
                OUTPUT_VARIABLE IncludeFileRelativePath)
            cmake_path(APPEND "@TARGET_NAME_TOKEN@" ${CMAKE_INSTALL_INCLUDEDIR} ${IncludeFileRelativePath} OUTPUT_VARIABLE IncludeFileInstallPath)
            list(APPEND InterfaceIncludeFiles "$<BUILD_INTERFACE:${FILE}>")
            list(APPEND InterfaceIncludeFiles "$<INSTALL_INTERFACE:${IncludeFileInstallPath}>")
        endforeach()

        # set("InterfaceIncludeFiles${FoldersLength}" "")
        # list(APPEND "InterfaceIncludeFiles${FoldersLength}" ${TmpHeader})
    endforeach()
endmacro(AddSourceFolder)

macro(NewTargetSource)
    set(SourceFiles "")
    set(PrivateIncludeFolders "")
    set(PublicIncludeFolders "")
    set(InterfaceIncludeFolders "")

    set(PrivateFiles "")
    set(PublicIncludeFiles "")
    set(InterfaceIncludeFiles "")
endmacro(NewTargetSource)

macro(AddTargetInclude TARGET_NAME)
    # list(LENGTH PrivateIncludeFolders FoldersLength)

    # if(${FoldersLength} GREATER 0)
    # MATH(EXPR FoldersLength "${FoldersLength}-1")

    # foreach(FolderIndex RANGE ${FoldersLength})
    # list(GET PrivateIncludeFolders ${FolderIndex} PrivateIncludeFolder)
    # list(LENGTH "PrivateFiles${FoldersLength}" FilesLength)

    # if(${FilesLength} GREATER 0)
    # target_include_directories(${TARGET_NAME}
    # PRIVATE ${PrivateIncludeFolder})
    # target_sources(${TARGET_NAME}
    # PRIVATE
    # ${PrivateFiles${FoldersLength}}
    # )
    # endif()
    # endforeach()
    # endif()

    # list(LENGTH PublicIncludeFolders FoldersLength)

    # if(${FoldersLength} GREATER 0)
    # MATH(EXPR FoldersLength "${FoldersLength}-1")

    # foreach(FolderIndex RANGE ${FoldersLength})
    # list(GET PublicIncludeFolders ${FolderIndex} PublicIncludeFolder)
    # list(LENGTH "PublicIncludeFiles${FoldersLength}" FilesLength)

    # if(${FilesLength} GREATER 0)
    # MATH(EXPR FilesLength "${FilesLength}-1")

    # foreach(FileIndex RANGE ${FilesLength})
    # list(GET "PublicIncludeFiles${FoldersLength}" ${FileIndex} PublicIncludeFile)
    # cmake_path(RELATIVE_PATH PublicIncludeFile
    # BASE_DIRECTORY ${PublicIncludeFolder}
    # OUTPUT_VARIABLE PublicIncludeFileRelativePath)
    # cmake_path(APPEND TARGET_NAME CMAKE_INSTALL_INCLUDEDIR PublicIncludeFileRelativePath OUTPUT_VARIABLE PublicIncludeFileInstallPath])
    # target_sources(${TARGET_NAME}
    # PUBLIC
    # FILE_SET HEADERS
    # BASE_DIRS ${PublicIncludeFolder}
    # FILES
    # $<BUILD_INTERFACE:${PublicIncludeFile}>
    # $<INSTALL_INTERFACE:${PublicIncludeFileInstallPath}>
    # )
    # endforeach()
    # endif()
    # endforeach()
    # endif()

    # list(LENGTH InterfaceIncludeFolders FoldersLength)

    # if(${FoldersLength} GREATER 0)
    # MATH(EXPR FoldersLength "${FoldersLength}-1")

    # foreach(FolderIndex RANGE ${FoldersLength})
    # list(GET InterfaceIncludeFolders ${FolderIndex} InterfaceIncludeFolder)
    # list(LENGTH "InterfaceIncludeFiles${FoldersLength}" FilesLength)

    # if(${FilesLength} GREATER 0)
    # MATH(EXPR FilesLength "${FilesLength}-1")

    # foreach(FileIndex RANGE ${FilesLength})
    # list(GET "InterfaceIncludeFiles${FoldersLength}" ${FileIndex} InterfaceIncludeFile)
    # cmake_path(RELATIVE_PATH InterfaceIncludeFile
    # BASE_DIRECTORY ${InterfaceIncludeFolder}
    # OUTPUT_VARIABLE InterfaceIncludeFileRelativePath)
    # cmake_path(APPEND TARGET_NAME CMAKE_INSTALL_INCLUDEDIR InterfaceIncludeFileRelativePath OUTPUT_VARIABLE InterfaceIncludeFileInstallPath])
    # target_sources(${TARGET_NAME}
    # INTERFACE
    # FILE_SET HEADERS
    # BASE_DIRS ${InterfaceIncludeFolder}
    # FILES
    # $<BUILD_INTERFACE:${InterfaceIncludeFile}>
    # $<INSTALL_INTERFACE:${InterfaceIncludeFileInstallPath}>
    # )
    # endforeach()
    # endif()
    # endforeach()
    # endif()
    list(LENGTH PrivateFiles FilesLength)

    if(${FilesLength} GREATER 0)
        target_include_directories(${TARGET_NAME}
            PRIVATE ${PrivateIncludeFolders}
        )
        target_sources(${TARGET_NAME}
            PRIVATE
            ${PrivateFiles}
        )
    endif()

    list(LENGTH PublicIncludeFiles FilesLength)

    if(${FilesLength} GREATER 0)
        string(REPLACE "@TARGET_NAME_TOKEN@" ${TARGET_NAME} FinalFiles "${PublicIncludeFiles}")
        target_sources(${TARGET_NAME}
            PUBLIC
            FILE_SET HEADERS
            BASE_DIRS ${PublicIncludeFolders}
            FILES
            ${FinalFiles}
        )
    endif()

    list(LENGTH InterfaceIncludeFiles FilesLength)

    if(${FilesLength} GREATER 0)
        string(REPLACE "@TARGET_NAME_TOKEN@" ${TARGET_NAME} FinalFiles "${InterfaceIncludeFiles}")
        target_sources(${TARGET_NAME}
            PUBLIC
            FILE_SET HEADERS
            BASE_DIRS ${InterfaceIncludeFolders}
            FILES
            ${FinalFiles}
        )
    endif()
endmacro(AddTargetInclude)

macro(AddTargetInstall TARGET_NAME TARGET_NAMESPACE)
    include(CMakePackageConfigHelpers)
    get_target_property(target_type ${TARGET_NAME} TYPE)

    if(NOT target_type STREQUAL "EXECUTABLE")
        add_library("${TARGET_NAMESPACE}::${TARGET_NAME}" ALIAS ${TARGET_NAME})
    endif()

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
        NAMESPACE ${TARGET_NAMESPACE}::
        DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}
    )

    configure_package_config_file(
        ${OCMAKEUTIL_PROJECTS_PATH}/CommonConfig.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}Config.cmake
        INSTALL_DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}
    )

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}Config.cmake
        DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}
    )

    if(DEFINED ${TARGET_NAME}_VERSION_STRING)
        write_basic_package_version_file(
            ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}ConfigVersion.cmake
            VERSION ${${TARGET_NAME}_VERSION_STRING}
            COMPATIBILITY AnyNewerVersion)

        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}ConfigVersion.cmake
            DESTINATION ${TARGET_NAME}/${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}
        )
    endif()
endmacro(AddTargetInstall)
