# Once done these will be defined:
#
# * SteamLanguageParser_FOUND
# * SteamLanguageParser_EXE_PATH
# * SteamLanguageParser_PATH


find_path(
  SteamLanguageParser_PATH
  NAMES SteamLanguageParser.exe
  HINTS ${CMAKE_SYSTEM_PROGRAM_PATH}
  #PATH_SUFFIXES bin
  )
set(SteamLanguageParser_EXE_PATH ${SteamLanguageParser_PATH}/SteamLanguageParser.exe)
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SteamLanguageParser REQUIRED_VARS SteamLanguageParser_PATH )
mark_as_advanced(SteamLanguageParser_PATH SteamLanguageParser_EXE_PATH)
