cmake_minimum_required(VERSION 3.24)
include(RegexHelper)

function(FindInPath ProjectName Path)
	set(options CONFIG REQUIRED)
	set(oneValueArgs)
	set(multiValueArgs)

	cmake_parse_arguments(FindInPath
		"${options}"
		"${oneValueArgs}"
		"${multiValueArgs}"
		${ARGN}
	)

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
endfunction()

function(AddPathToPrefix Path)
	list(APPEND CMAKE_PREFIX_PATH ${Path})
	set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE INTERNAL "")
endfunction()

function(PostImportProject)
	find_package(${ProjectName})

	if(ProjectName STREQUAL "TBB")
		target_compile_definitions(TBB::tbb INTERFACE -D__TBB_BUILD=1)
	elseif(ProjectName STREQUAL "tomlplusplus")
		target_compile_definitions(tomlplusplus::tomlplusplus
			INTERFACE -DTOML_ENABLE_UNRELEASED_FEATURES=1
		)
	elseif(ProjectName STREQUAL "LibArchive")
		if(NOT TARGET LibArchive::LibArchive_new)
			add_library(LibArchive_static_new INTERFACE)

			target_link_libraries(LibArchive_static_new
				INTERFACE LibArchive::LibArchive_static
			)
			target_compile_definitions(LibArchive_static_new
				INTERFACE -DLIBARCHIVE_STATIC
			)
			add_library(LibArchive_new INTERFACE)
			target_link_libraries(LibArchive_new
				INTERFACE LibArchive::LibArchive
			)
			find_package(ZLIB)
			if(ZLIB_FOUND)
				target_link_libraries(LibArchive_static_new
					INTERFACE ZLIB::ZLIB
				)
				target_link_libraries(LibArchive_new
					INTERFACE ZLIB::ZLIB
				)
			endif()
			add_library(LibArchive::LibArchive_new ALIAS LibArchive_new)
			add_library(LibArchive::LibArchive_static_new ALIAS LibArchive_static_new)
		endif()
	endif()
endfunction()

function(ImportProject ProjectName)
	set(options STATIC_CRT STATIC SSH FIND)
	set(oneValueArgs URL TAG BIT EXTERNAL_DIR)
	set(multiValueArgs)

	cmake_parse_arguments(IMPORT_PROJECT
		"${options}"
		"${oneValueArgs}"
		"${multiValueArgs}"
		${ARGN}
	)

	set(WORKING_DIRECTORY_SUFFIX
		"${WORKING_DIRECTORY_SUFFIX}_${CMAKE_CXX_COMPILER_ID}"
	)

	if(IMPORT_PROJECT_STATIC_CRT)
		set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_STATIC_CRT")
	endif()

	if(IMPORT_PROJECT_STATIC)
		set(WORKING_DIRECTORY_SUFFIX "${WORKING_DIRECTORY_SUFFIX}_STATIC")

		if(ProjectName STREQUAL "ZLIB")
			set(ZLIB_USE_STATIC_LIBS ON CACHE BOOL "" FORCE)
		endif()
	endif()

	if(NOT IMPORT_PROJECT_BIT)
		math(EXPR IMPORT_PROJECT_BIT "${CMAKE_SIZEOF_VOID_P}*8")
		set(WORKING_DIRECTORY_SUFFIX
			"${WORKING_DIRECTORY_SUFFIX}_${IMPORT_PROJECT_BIT}"
		)
	endif()

	if(IMPORT_PROJECT_TAG)
		set(WORKING_DIRECTORY_SUFFIX
			"${WORKING_DIRECTORY_SUFFIX}_${IMPORT_PROJECT_TAG}"
		)
	endif()

	string(TOLOWER ${ProjectName} ProjectName_Lower)

	if(NOT IMPORT_PROJECT_EXTERNAL_DIR_CACHE)
		if(IMPORT_PROJECT_EXTERNAL_DIR)
			cmake_path(ABSOLUTE_PATH
				IMPORT_PROJECT_EXTERNAL_DIR
				BASE_DIRECTORY
				${CMAKE_SOURCE_DIR}
				NORMALIZE
				OUTPUT_VARIABLE
				IMPORT_PROJECT_EXTERNAL_DIR
			)
		else()
			set(IMPORT_PROJECT_EXTERNAL_DIR ${CMAKE_SOURCE_DIR}/external)
			cmake_path(NORMAL_PATH IMPORT_PROJECT_EXTERNAL_DIR)
		endif()
		set(
			IMPORT_PROJECT_EXTERNAL_DIR_CACHE
			${IMPORT_PROJECT_EXTERNAL_DIR}
			CACHE
				INTERNAL
				""
		)
	endif()

	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}${WORKING_DIRECTORY_SUFFIX}
	)
	set(INSTALL_DIRECTORY ${WORKING_DIRECTORY}/install)

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

		if(ProjectName STREQUAL "spdlog")
			ImportSPDLOG()
		elseif(ProjectName STREQUAL "concurrentqueue")
			ImportCONCURRENTQUEUE()
		elseif(ProjectName STREQUAL "PalSigslot")
			ImportPalSigslot()
		elseif(ProjectName STREQUAL "ZLIB")
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
		elseif(ProjectName STREQUAL "SOCI")
			ImportSOCI()
		elseif(ProjectName STREQUAL "DirectXTex")
			ImportDirectXTex()
		elseif(ProjectName STREQUAL "CapnProto")
			ImportCapnProto()
		elseif(ProjectName STREQUAL "re2")
			ImportRE2()
		elseif(ProjectName STREQUAL "steamdatapp")
			ImportSTEAMDATAPP()
		elseif(ProjectName STREQUAL "ValveFileVDF")
			ImportValveFileVDF()
		elseif(ProjectName STREQUAL "LazyImporter")
			ImportLazyImporter()
		elseif(ProjectName STREQUAL "cxxopts")
			Importcxxopts()
		elseif(ProjectName STREQUAL "tomlplusplus")
			Importtomlplusplus()
		elseif(ProjectName STREQUAL "magic_enum")
			Importmagic_enum()
		elseif(ProjectName STREQUAL "Glob")
			ImportGlob()
		elseif(ProjectName STREQUAL "Taskflow")
			ImportTaskflow()
		elseif(ProjectName STREQUAL "ctre")
			Importctre()
		elseif(ProjectName STREQUAL "inih")
			Importinih()
		elseif(ProjectName STREQUAL "LibArchive")
			ImportLibArchive()
		elseif(ProjectName STREQUAL "wildmatch")
			Importwildmatch()
		else()
			message(FATAL_ERROR "no project ${ProjectName} to import")
		endif()
	else()
		message(STATUS "Before Import Find ${ProjectName}")

		if(${ProjectName}_DIR)
			message(STATUS
				"Before Import Find ${ProjectName} DIR :${${ProjectName}_DIR}"
			)
		endif()

		if(${ProjectName}_INCLUDE_DIR)
			message(STATUS
				"Before Import Find ${ProjectName} INCLUDE_DIR :${${ProjectName}_INCLUDE_DIR}"
			)
		endif()
	endif()

	PostImportProject()
endfunction()

function(ImportSPDLOG)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing SPDLOG tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:gabime/spdlog.git")
	else()
		set(GIT_REPOSITORY "https://github.com/gabime/spdlog.git")
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportCONCURRENTQUEUE)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing concurrentqueue tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:cameron314/concurrentqueue.git")
	else()
		set(GIT_REPOSITORY "https://github.com/cameron314/concurrentqueue.git")
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportPalSigslot)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing sigslot tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:palacaze/sigslot.git")
	else()
		set(GIT_REPOSITORY "https://github.com/palacaze/sigslot.git")
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportZLIB)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportCURL)
	# already define CMAKE_DEBUG_POSTFIX
	# build_shared or static
	if(IMPORT_PROJECT_STATIC)
		set(CURL_USE_STATIC_LIBS "ON" PARENT_SCOPE)
	endif()

	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportSQLITE3)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} CONFIG)

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
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
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} CONFIG REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportLIBUV)
	# already define CMAKE_DEBUG_POSTFIX
	# build_both shared static
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportDETOURS)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix/src/${ProjectName_Lower}
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportSDL2)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportSDL3)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportSDL2_image)
	set(SDL2IMAGE_VENDORED TRUE)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportSDL3_image)
	set(SDL3IMAGE_VENDORED TRUE)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportMbedTLS)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportGLEW)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	# compile debug release in same time
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportRAPIDFUZZ)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	# header only library
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportxxHash)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	if(IMPORT_PROJECT_STATIC)
		set(BUILD_SHARED_LIBS FALSE)
	else()
		set(BUILD_SHARED_LIBS TRUE)
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportZSTD)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportBOOST)
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

	set(DEFAULT_URL
		https://github.com/boostorg/boost/releases/download/boost-1.87.0/boost-1.87.0-cmake.tar.xz
	)

	if(IMPORT_PROJECT_URL STREQUAL "")
		set(IMPORT_PROJECT_URL ${DEFAULT_URL})
	elseif(NOT url)
		set(IMPORT_PROJECT_URL ${DEFAULT_URL})
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportOPENSSL)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)

	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportQINIU)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)

	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportFOLLY)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)

	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportTBB)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)

	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportMINIZIP)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportSTEAM)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}
	)
	set(${ProjectName}_INSTALL_DIR ${WORKING_DIRECTORY}/_deps/steam-src)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		set(IMPORT_PROJECT_TAG main)
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:rlabrecque/SteamworksSDK.git")
	else()
		set(GIT_REPOSITORY "https://github.com/rlabrecque/SteamworksSDK.git")
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportCPUID)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportProtobuf)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} CONFIG REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportLIBWEBSOCKETS)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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
		set(GIT_REPOSITORY "https://github.com/warmcat/libwebsockets.git")
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportABSL)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${PROJECT_INSTALL_DIR})
endfunction()

function(ImportSIMDJSON)
	# simdjson build both static and shared library .
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportRAPIDJSON)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	# delete RapidJSON_DIR
	file(READ "${${ProjectName}_INSTALL_DIR}/cmake/RapidJSONConfig.cmake"
		FILE_CONTENT
	)
	string(REGEX
		REPLACE
		"[^\r\n]*RapidJSON_DIR[^\r\n]*(\r?\n|\r)?"
		""
		FILE_CONTENT
		"${FILE_CONTENT}"
	)
	string(REGEX
		MATCH
		"[^\r\n]*endif()[^\r\n]*(\r?\n|\r)?"
		ADD_LIBRARY_CONTENT
		"${FILE_CONTENT}"
	)
	string(APPEND
		ADD_LIBRARY_CONTENT
		[[
if(NOT TARGET RapidJSON::RapidJSON)
  add_library(RapidJSON::RapidJSON ALIAS RapidJSON)
endif()
    ]]
	)
	string(REGEX
		REPLACE
		"[^\r\n]*endif()[^\r\n]*(\r?\n|\r)?"
		"${ADD_LIBRARY_CONTENT}"
		FILE_CONTENT
		"${FILE_CONTENT}"
	)
	file(WRITE "${${ProjectName}_INSTALL_DIR}/cmake/RapidJSONConfig.cmake"
		"${FILE_CONTENT}"
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportSQLPP23)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportSOCI)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:SOCI/soci.git")
	else()
		set(GIT_REPOSITORY "https://github.com/SOCI/soci.git")
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportDirectXTex)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportCapnProto)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportRE2)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:google/re2.git")
	else()
		set(GIT_REPOSITORY "https://github.com/google/re2.git")
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportSTEAMDATAPP)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:wsw364321644/steamdatapp.git")
	else()
		set(GIT_REPOSITORY "https://github.com/wsw364321644/steamdatapp.git")
	endif()

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportValveFileVDF)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR
			"missing tag (install fix after 9138f83d310fc3f656297f79a9b43d0a5d45cd4e)"
		)
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:TinyTinni/ValveFileVDF.git")
	else()
		set(GIT_REPOSITORY "https://github.com/TinyTinni/ValveFileVDF.git")
	endif()

	# header only
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/simple_project.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportLazyImporter)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:JustasMasiulis/lazy_importer.git")
	else()
		set(GIT_REPOSITORY "https://github.com/JustasMasiulis/lazy_importer.git")
	endif()

	# header only
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(Importcxxopts)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:jarro2783/cxxopts.git")
	else()
		set(GIT_REPOSITORY "https://github.com/jarro2783/cxxopts.git")
	endif()

	set(EXTERNALPROJECT_OPTION_EX
		-DCXXOPTS_BUILD_TESTS:BOOL=OFF
		-DCXXOPTS_BUILD_EXAMPLES:BOOL=OFF
	)

	# header only
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/simple_project.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(Importtomlplusplus)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:marzer/tomlplusplus.git")
	else()
		set(GIT_REPOSITORY "https://github.com/marzer/tomlplusplus.git")
	endif()

	# header only
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/simple_project.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(Importmagic_enum)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:Neargye/magic_enum.git")
	else()
		set(GIT_REPOSITORY "https://github.com/Neargye/magic_enum.git")
	endif()

	set(EXTERNALPROJECT_OPTION_EX
		-DMAGIC_ENUM_OPT_BUILD_EXAMPLES:bool=OFF
		-DMAGIC_ENUM_OPT_BUILD_TESTS:bool=OFF
	)

	# header only
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/simple_project.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportGlob)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:p-ranav/glob.git")
	else()
		set(GIT_REPOSITORY "https://github.com/p-ranav/glob.git")
	endif()

	# header only
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportTaskflow)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:taskflow/taskflow.git")
	else()
		set(GIT_REPOSITORY "https://github.com/taskflow/taskflow.git")
	endif()

	set(EXTERNALPROJECT_OPTION_EX
		-DTF_BUILD_TESTS:BOOL=OFF
		-DTF_BUILD_EXAMPLES:BOOL=OFF
		-DTF_BUILD_PROFILER:BOOL=OFF
		-DTF_BUILD_BENCHMARKS:BOOL=OFF
	)

	# header only
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/simple_project.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(Importctre)
	set(WORKING_DIRECTORY
		${IMPORT_PROJECT_EXTERNAL_DIR_CACHE}/${ProjectName_Lower}_${IMPORT_PROJECT_BIT}
	)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY
			"git@github.com:hanickadot/compile-time-regular-expressions.git"
		)
	else()
		set(GIT_REPOSITORY
			"https://github.com/hanickadot/compile-time-regular-expressions.git"
		)
	endif()

	# header only
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/simple_project.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(Importinih)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
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

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(ImportLibArchive)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing LibArchive tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:libarchive/libarchive.git")
	else()
		set(GIT_REPOSITORY "https://github.com/libarchive/libarchive.git")
	endif()

	find_package(OpenSSL)
	if(OpenSSL_FOUND)
		set(ENABLE_OPENSSL ON)
	else()
		set(ENABLE_OPENSSL OFF)
	endif()

	find_package(ZLIB)
	if(ZLIB_FOUND)
		set(ENABLE_ZLIB ON)
	else()
		set(ENABLE_ZLIB OFF)
	endif()

	find_package(zstd)
	if(zstd_FOUND)
		set(ENABLE_ZSTD ON)
	else()
		set(ENABLE_ZSTD OFF)
	endif()

	find_package(BZip2)
	if(BZip2_FOUND)
		set(ENABLE_BZip2 ON)
	else()
		set(ENABLE_BZip2 OFF)
	endif()

	find_package(LibLZMA)
	if(LibLZMA_FOUND)
		set(ENABLE_LZMA ON)
	else()
		set(ENABLE_LZMA OFF)
	endif()

	set(ENABLE_LZ4 OFF)
	set(ENABLE_LIBXML2 OFF)
	set(ENABLE_EXPAT OFF)
	set(ENABLE_WIN32_XMLLITE OFF)
	set(ENABLE_PCREPOSIX OFF)
	set(ENABLE_PCRE2POSIX OFF)
	set(ENABLE_LIBGCC OFF)
	if(WIN32)
		set(ENABLE_CNG ON)
	else()
		set(ENABLE_CNG OFF)
	endif()

	if(IMPORT_PROJECT_STATIC)
		set(BUILD_SHARED_LIBS OFF)
		set(ZLIB_USE_STATIC_LIBS ON CACHE BOOL "" FORCE)
	else()
		set(ZLIB_USE_STATIC_LIBS OFF CACHE BOOL "" FORCE)
		set(BUILD_SHARED_LIBS ON)
	endif()

	set(EXTERNALPROJECT_OPTION_EX
		-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
		-DZLIB_USE_STATIC_LIBS:BOOL=${ZLIB_USE_STATIC_LIBS}
		-DENABLE_OPENSSL:BOOL=${ENABLE_OPENSSL}
		-DENABLE_ZLIB:BOOL=${ENABLE_ZLIB}
		-DENABLE_ZSTD:BOOL=${ENABLE_ZSTD}
		-DENABLE_BZip2:BOOL=${ENABLE_BZip2}
		-DENABLE_LZMA:BOOL=${ENABLE_LZMA}
		-DENABLE_LZ4:BOOL=OFF
		-DENABLE_LIBXML2:BOOL=OFF
		-DENABLE_EXPAT:BOOL=OFF
		-DENABLE_WIN32_XMLLITE:BOOL=OFF
		-DENABLE_PCREPOSIX:BOOL=OFF
		-DENABLE_PCRE2POSIX:BOOL=OFF
		-DENABLE_LIBGCC:BOOL=OFF
		-DENABLE_CNG:BOOL=${ENABLE_CNG}
		-DENABLE_TEST:BOOL=OFF
		-DPOSIX_REGEX_LIB:STRING=LIBC
		-DMSVC_USE_STATIC_CRT:BOOL=${IMPORT_PROJECT_STATIC_CRT}
	)

	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/simple_project.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Debug
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()

function(Importwildmatch)
	set(${ProjectName}_INSTALL_DIR
		${WORKING_DIRECTORY}/${ProjectName_Lower}-prefix
	)
	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR})

	if(FindInPath_FOUND)
		AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
		return()
	endif()

	if(NOT IMPORT_PROJECT_TAG)
		message(SEND_ERROR "missing tag")
	endif()

	if(IMPORT_PROJECT_SSH)
		set(GIT_REPOSITORY "git@github.com:davvid/wildmatch.git")
	else()
		set(GIT_REPOSITORY "https://github.com/davvid/wildmatch.git")
	endif()

	# header only
	configure_file(
		${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${ProjectName_Lower}.txt.in
		${WORKING_DIRECTORY}/CMakeLists.txt
		@ONLY
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} ${CMAKE_GENERATOR_ARGV} .
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build . --target INSTALL --config Release
		WORKING_DIRECTORY ${WORKING_DIRECTORY}
	)

	FindInPath(${ProjectName} ${${ProjectName}_INSTALL_DIR} REQUIRED)
	AddPathToPrefix(${${ProjectName}_INSTALL_DIR})
endfunction()