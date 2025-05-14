# Once done these will be defined:
#
# * STEAM_LIB_NAME
# * STEAM_FOUND
# * STEAM_INCLUDE_DIRS
# * STEAM_LIBRARIES
# * Target Steam::Steam

if(CMAKE_SYSTEM_NAME MATCHES "Windows")
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(STEAM_LIB_NAME steam_api64)
  else()
    set(STEAM_LIB_NAME steam_api)
  endif()
elseif(CMAKE_SYSTEM_NAME MATCHES "Linux")
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(STEAM_LIB_NAME libsteam_api)
  else()
    set(STEAM_LIB_NAME libsteam_api)
  endif()
elseif(CMAKE_SYSTEM_NAME MATCHES "Darwin")
  set(STEAM_LIB_NAME libsteam_api)
else()
  message(FATAL_ERROR "Unsupported platform for Steam SDK")
endif()

find_path(
  STEAM_INCLUDE_DIR
  NAMES steam_api.h
  HINTS ENV STEAM_PATH ${STEAM_PATH} ${CMAKE_SOURCE_DIR}/${STEAM_PATH}
  PATHS ${Steam_ROOT} ${STEAM_ROOT}
  PATH_SUFFIXES public/steam)

find_library(
  STEAM_LIB
  NAMES ${STEAM_LIB_NAME}
  HINTS ENV STEAM_PATH ${STEAM_PATH} ${CMAKE_SOURCE_DIR}/${STEAM_PATH}
  PATHS ${Steam_ROOT} ${STEAM_ROOT}
  PATH_SUFFIXES
  redistributable_bin
  redistributable_bin/win64
  redistributable_bin/osx
  redistributable_bin/linux32
  redistributable_bin/linux64)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Steam DEFAULT_MSG STEAM_LIB
  STEAM_INCLUDE_DIR)
mark_as_advanced(STEAM_INCLUDE_DIR STEAM_LIB)

if(STEAM_FOUND)
  set(STEAM_INCLUDE_DIRS ${STEAM_INCLUDE_DIR})
  set(STEAM_LIBRARIES ${STEAM_LIB})

  if(NOT TARGET Steam::Steam)
    if(IS_ABSOLUTE "${STEAM_LIBRARIES}")
      add_library(Steam::Steam UNKNOWN IMPORTED)
      set_target_properties(Steam::Steam PROPERTIES IMPORTED_LOCATION
        "${STEAM_LIBRARIES}")
    else()
      add_library(Steam::Steam INTERFACE IMPORTED)
      set_target_properties(Steam::Steam PROPERTIES IMPORTED_LIBNAME
        "${STEAM_LIBRARIES}")
    endif()

    set_target_properties(
      Steam::Steam PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
      "${STEAM_INCLUDE_DIRS}")
  endif()
endif()
