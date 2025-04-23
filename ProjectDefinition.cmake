cmake_minimum_required(VERSION 3.20)
include(GNUInstallDirs)

FUNCTION(EXCLUDE_FILES_FROM_DIR_IN_LIST _InFileList _excludeDirName)
	foreach(ITR ${_InFileList})
		if("${ITR}" MATCHES "(.*)${_excludeDirName}(.*)") # Check if the item matches the directory name in _excludeDirName
			list(REMOVE_ITEM _InFileList ${ITR}) # Remove the item from the list
		endif("${ITR}" MATCHES "(.*)${_excludeDirName}(.*)")
	endforeach(ITR)

	set(EXCLUDED_FILES ${_InFileList} PARENT_SCOPE) # Return the SOURCE_FILES variable to the calling parent
ENDFUNCTION(EXCLUDE_FILES_FROM_DIR_IN_LIST)

macro(SearchSourceFiles FolderPath IsRecurse)
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

	if(${IsRecurse})
		file(GLOB_RECURSE TmpSource LIST_DIRECTORIES false CONFIGURE_DEPENDS ${TmpHHeader} ${TmpHppHeader} ${TmpC} ${TmpCC} ${TmpCpp} ${TmpIcon} ${TmpRC})
	else()
		file(GLOB TmpSource LIST_DIRECTORIES false CONFIGURE_DEPENDS ${TmpHHeader} ${TmpHppHeader} ${TmpC} ${TmpCC} ${TmpCpp} ${TmpIcon} ${TmpRC})
	endif()

	if(${IsRecurse})
		file(GLOB_RECURSE TmpAsmSource LIST_DIRECTORIES false CONFIGURE_DEPENDS ${TmpS} ${TmpAsm})
	else()
		file(GLOB TmpAsmSource LIST_DIRECTORIES false CONFIGURE_DEPENDS ${TmpS} ${TmpAsm})
	endif()

	set_property(SOURCE TmpAsmSource APPEND PROPERTY COMPILE_OPTIONS "-x" "assembler-with-cpp")

	list(APPEND TmpSource ${TmpAsmSource})

	if(WIN32)
		EXCLUDE_FILES_FROM_DIR_IN_LIST("${TmpSource}" "Linux")
		EXCLUDE_FILES_FROM_DIR_IN_LIST("${TmpSource}" "linux")

	# message(STATUS "EXCLUDED_FILES ${EXCLUDED_FILES}")
	elseif(UNIX)
		EXCLUDE_FILES_FROM_DIR_IN_LIST("${TmpSource}" "Windows")
		EXCLUDE_FILES_FROM_DIR_IN_LIST("${TmpSource}" "windows")
	endif()

	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		EXCLUDE_FILES_FROM_DIR_IN_LIST("${EXCLUDED_FILES}" "X86")
		EXCLUDE_FILES_FROM_DIR_IN_LIST("${EXCLUDED_FILES}" "x86")
	elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
		EXCLUDE_FILES_FROM_DIR_IN_LIST("${EXCLUDED_FILES}" "X64")
		EXCLUDE_FILES_FROM_DIR_IN_LIST("${EXCLUDED_FILES}" "x64")
	endif()

	# message(STATUS "EXCLUDED_FILES ${EXCLUDED_FILES}")
	# if(NOT EXCLUDED_FILES STREQUAL "")
	# set(SourceFiles "${SourceFiles};${EXCLUDED_FILES}")
	# endif()
	list(APPEND SourceFiles ${EXCLUDED_FILES})
endmacro(SearchSourceFiles)

macro(AddSourceFolder)
	set(options INCLUDE RECURSE)
	set(oneValueArgs)
	set(multiValueArgs PUBLIC PRIVATE INTERFACE)
	cmake_parse_arguments(AddSourceFolder "${options}" "${oneValueArgs}"
		"${multiValueArgs}" ${ARGN})

	foreach(LETTER ${AddSourceFolder_PRIVATE})
		list(LENGTH PrivateIncludeFolders FoldersLength)
		list(APPEND PrivateIncludeFolders ${LETTER})
		SearchSourceFiles(${LETTER} ${AddSourceFolder_RECURSE})
		set("PrivateIncludeFiles${FoldersLength}" "")
		list(APPEND "PrivateIncludeFiles${FoldersLength}" ${EXCLUDED_FILES})
	endforeach()

	foreach(LETTER ${AddSourceFolder_UNPARSED_ARGUMENTS})
		list(LENGTH PrivateIncludeFolders FoldersLength)
		list(APPEND PrivateIncludeFolders ${LETTER})
		SearchSourceFiles(${LETTER} ${AddSourceFolder_RECURSE})
		set("PrivateIncludeFiles${FoldersLength}" "")
		list(APPEND "PrivateIncludeFiles${FoldersLength}" ${EXCLUDED_FILES})
	endforeach()

	foreach(LETTER ${AddSourceFolder_PUBLIC})
		list(LENGTH PublicIncludeFolders FoldersLength)
		list(APPEND PublicIncludeFolders ${LETTER})
		SearchSourceFiles(${LETTER} ${AddSourceFolder_RECURSE})
		set("PublicIncludeFiles${FoldersLength}" "")
		list(APPEND "PublicIncludeFiles${FoldersLength}" ${EXCLUDED_FILES})
	endforeach()

	foreach(LETTER ${AddSourceFolder_INTERFACE})
		list(LENGTH InterfaceIncludeFolders FoldersLength)
		list(APPEND InterfaceIncludeFolders ${LETTER})
		SearchSourceFiles(${LETTER} ${AddSourceFolder_RECURSE})
		set("InterfaceIncludeFiles${FoldersLength}" "")
		list(APPEND "InterfaceIncludeFiles${FoldersLength}" ${EXCLUDED_FILES})
	endforeach()
endmacro(AddSourceFolder)

macro(NewTargetSource)
	set(SourceFiles "")
	set(PrivateIncludeFolders "")
	set(PublicIncludeFolders "")
	set(InterfaceIncludeFolders "")

	# set(PrivateIncludeFiles "")
	# set(PublicIncludeFiles "")
	# set(InterfaceIncludeFiles "")
endmacro(NewTargetSource)

macro(AddTargetInclude TARGET_NAME)
	# foreach(folderpath IN LISTS PublicIncludeFolders)
	# target_include_directories(${TARGET_NAME}
	# PUBLIC $<BUILD_INTERFACE:${folderpath}>
	# $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
	# )
	# endforeach()

	# foreach(folderpath IN LISTS PrivateIncludeFolders)
	# target_include_directories(${TARGET_NAME}
	# PRIVATE $<BUILD_INTERFACE:${folderpath}>
	# $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
	# )
	# endforeach()

	# foreach(folderpath IN LISTS InterfaceIncludeFolders)
	# target_include_directories(${TARGET_NAME}
	# INTERFACE $<BUILD_INTERFACE:${folderpath}>
	# $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
	# )
	# endforeach()

	# set_target_properties(${TARGET_NAME} PROPERTIES PUBLIC_HEADER "${PublicIncludeFiles}${InterfaceIncludeFiles}")
	list(LENGTH PrivateIncludeFolders FoldersLength)

	if(${FoldersLength} GREATER 0)
		MATH(EXPR FoldersLength "${FoldersLength}-1")

		foreach(FolderIndex RANGE ${FoldersLength})
			list(GET PrivateIncludeFolders ${FolderIndex} PrivateIncludeFolder)
			list(LENGTH "PrivateIncludeFiles${FoldersLength}" FilesLength)

			if(${FilesLength} GREATER 0)
				target_include_directories(${TARGET_NAME}
					PRIVATE ${PrivateIncludeFolder})
				target_sources(${TARGET_NAME}
					PRIVATE
					${PrivateIncludeFiles${FoldersLength}}
				)

				# MATH(EXPR FilesLength "${FilesLength}-1")

				# foreach(FileIndex RANGE ${FilesLength})
				# list(GET "PrivateIncludeFiles${FoldersLength}" ${FileIndex} PrivateIncludeFile)
				# target_sources(${TARGET_NAME}
				# PRIVATE
				# ${PrivateIncludeFile}
				# )
				# endforeach()
			endif()
		endforeach()
	endif()

	list(LENGTH PublicIncludeFolders FoldersLength)

	if(${FoldersLength} GREATER 0)
		MATH(EXPR FoldersLength "${FoldersLength}-1")

		foreach(FolderIndex RANGE ${FoldersLength})
			list(GET PublicIncludeFolders ${FolderIndex} PublicIncludeFolder)
			list(LENGTH "PublicIncludeFiles${FoldersLength}" FilesLength)

			if(${FilesLength} GREATER 0)
				MATH(EXPR FilesLength "${FilesLength}-1")

				foreach(FileIndex RANGE ${FilesLength})
					list(GET "PublicIncludeFiles${FoldersLength}" ${FileIndex} PublicIncludeFile)
					cmake_path(RELATIVE_PATH PublicIncludeFile
						BASE_DIRECTORY ${PublicIncludeFolder}
						OUTPUT_VARIABLE PublicIncludeFileRelativePath)
					cmake_path(APPEND TARGET_NAME CMAKE_INSTALL_INCLUDEDIR PublicIncludeFileRelativePath OUTPUT_VARIABLE PublicIncludeFileInstallPath])
					target_sources(${TARGET_NAME}
						PUBLIC
						FILE_SET HEADERS
						BASE_DIRS ${PublicIncludeFolder}
						FILES
						$<BUILD_INTERFACE:${PublicIncludeFile}>
						$<INSTALL_INTERFACE:${PublicIncludeFileInstallPath}>
					)
				endforeach()
			endif()
		endforeach()
	endif()

	list(LENGTH InterfaceIncludeFolders FoldersLength)

	if(${FoldersLength} GREATER 0)
		MATH(EXPR FoldersLength "${FoldersLength}-1")

		foreach(FolderIndex RANGE ${FoldersLength})
			list(GET InterfaceIncludeFolders ${FolderIndex} InterfaceIncludeFolder)
			list(LENGTH "InterfaceIncludeFiles${FoldersLength}" FilesLength)

			if(${FilesLength} GREATER 0)
				MATH(EXPR FilesLength "${FilesLength}-1")

				foreach(FileIndex RANGE ${FilesLength})
					list(GET "InterfaceIncludeFiles${FoldersLength}" ${FileIndex} InterfaceIncludeFile)
					cmake_path(RELATIVE_PATH InterfaceIncludeFile
						BASE_DIRECTORY ${InterfaceIncludeFolder}
						OUTPUT_VARIABLE InterfaceIncludeFileRelativePath)
					cmake_path(APPEND TARGET_NAME CMAKE_INSTALL_INCLUDEDIR InterfaceIncludeFileRelativePath OUTPUT_VARIABLE InterfaceIncludeFileInstallPath])
					target_sources(${TARGET_NAME}
						INTERFACE
						FILE_SET HEADERS
						BASE_DIRS ${InterfaceIncludeFolder}
						FILES
						$<BUILD_INTERFACE:${InterfaceIncludeFile}>
						$<INSTALL_INTERFACE:${InterfaceIncludeFileInstallPath}>
					)
				endforeach()
			endif()
		endforeach()
	endif()
endmacro(AddTargetInclude)

macro(AddTargetInstall TARGET_NAME TARGET_NAMESPACE)
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
endmacro(AddTargetInstall)

MACRO(ADD_DELAYLOAD_FLAGS flagsVar)
	SET(dlls "${ARGN}")

	FOREACH(dll ${dlls})
		SET(${flagsVar} "${${flagsVar}} /DELAYLOAD:${dll}.dll")
	ENDFOREACH()
ENDMACRO()
