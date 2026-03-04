# Once done these will be defined:
#
# * SteamLanguageParser_FOUND
# * SteamLanguageParser_DIR
# * SteamLanguageParser_PATH


find_path(
  SteamLanguageParser_DIR
  NAMES SteamLanguageParser.exe
  HINTS ${CMAKE_SYSTEM_PROGRAM_PATH}
  #PATH_SUFFIXES bin
  )
set(SteamLanguageParser_PATH ${SteamLanguageParser_DIR}/SteamLanguageParser.exe)
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SteamLanguageParser REQUIRED_VARS SteamLanguageParser_DIR )
mark_as_advanced(SteamLanguageParser_DIR SteamLanguageParser_PATH)
