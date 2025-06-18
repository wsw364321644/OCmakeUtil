function(msvs::directory out-var)
  if(${out-var})
    return()
  endif()

  cmake_parse_arguments(ARG "" "VARIABLE;PATH;DOC" "" ${ARGN})
  message(CHECK_START "Searching for ${ARG_DOC}")

  # We want to get the list of options, but *not* the full path string, hence
  # the use of `RELATIVE`
  file(GLOB candidates
    LIST_DIRECTORIES YES
    RELATIVE "${ARG_PATH}"
    "${ARG_PATH}/*")
  list(SORT candidates COMPARE NATURAL ORDER DESCENDING)

  if(NOT DEFINED ARG_VARIABLE OR NOT ${ARG_VARIABLE})
    list(GET candidates 0 ${out-var})
  else()
    foreach(candidate IN LISTS candidates)
      if(candidate VERSION_GREATER_EQUAL ${ARG_VARIABLE})
        set(${out-var} "${candidate}")
        break()
      endif()
    endforeach()
  endif()

  if(NOT ${out-var})
    message(CHECK_FAIL "not found")
  else()
    message(CHECK_PASS "found : ${${out-var}}")
    set(${out-var} "${${out-var}}" CACHE STRING "${out-var} value" FORCE)
  endif()
endfunction()

function(FindVisualStudio)
  cmake_path(
    CONVERT "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio/Installer"
    TO_CMAKE_PATH_LIST vswhere.dir
    NORMALIZE)

  # This only temporarily affects the variable since we're inside a block.
  list(APPEND CMAKE_SYSTEM_PROGRAM_PATH "${vswhere.dir}")
  find_program(VSWHERE_EXECUTABLE NAMES vswhere DOC "Visual Studio Locator" REQUIRED)

  if(DEFINED IZ_MSVS_EDITION)
    set(product "Microsoft.VisualStudio.Product.${IZ_MSVS_EDITION}")
  else()
    set(product "*")
  endif()

  message(CHECK_START "Searching for Visual Studio ${IZ_MSVS_EDITION}")
  execute_process(COMMAND "${VSWHERE_EXECUTABLE}" -nologo -nocolor
    -format json
    -products "${product}"
    -utf8
    -sort
    ENCODING UTF-8
    OUTPUT_VARIABLE candidates
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  string(JSON candidates.length LENGTH "${candidates}")
  string(JOIN " " error "Could not find Visual Studio"
    "${IZ_MSVS_VERSION}"
    "${IZ_MSVS_EDITION}")

  if(candidates.length EQUAL 0)
    message(CHECK_FAIL "no products")

    # You can choose to either hard fail here, or continue
    message(FATAL_ERROR "${error}")
  endif()

  if(NOT IZ_MSVS_VERSION)
    string(JSON candidate.install.path GET "${candidates}" 0 "installationPath")
  else()
    # Unfortunately, range operations are inclusive in CMake for god knows why
    math(EXPR stop "${candidates.length} - 1")

    foreach(idx RANGE 0 ${stop})
      string(JSON version GET "${candidates}" ${idx} "catalog" "productLineVersion")

      if(version VERSION_EQUAL IZ_MSVS_VERSION)
        string(JSON candidate.install.path
          GET "${candidates}" ${idx} "installationPath")
        break()
      endif()
    endforeach()
  endif()

  if(NOT candidate.install.path)
    message(CHECK_FAIL "no install path found")
    message(FATAL_ERROR "${error}")
  endif()

  cmake_path(
    CONVERT "${candidate.install.path}"
    TO_CMAKE_PATH_LIST candidate.install.path
    NORMALIZE)
  message(CHECK_PASS "found : ${candidate.install.path}")
  set(IZ_MSVS_INSTALL_PATH "${candidate.install.path}"
    CACHE PATH "Visual Studio Installation Path"
    FORCE)

  message(CHECK_START "Searching for Windows SDK Root Directory")
  cmake_host_system_information(RESULT IZ_MSVS_WINDOWS_SDK_ROOT QUERY
    WINDOWS_REGISTRY "HKLM/SOFTWARE/Microsoft/Windows Kits/Installed Roots"
    VALUE "KitsRoot10"
    VIEW BOTH
    ERROR_VARIABLE error
  )

  if(error)
    message(CHECK_FAIL "not found : ${error}")
  else()
    cmake_path(CONVERT "${IZ_MSVS_WINDOWS_SDK_ROOT}"
      TO_CMAKE_PATH_LIST IZ_MSVS_WINDOWS_SDK_ROOT
      NORMALIZE)
    set(IZ_MSVS_WINDOWS_SDK_ROOT "${IZ_MSVS_WINDOWS_SDK_ROOT}"
      CACHE PATH "Windows SDK Root Directory"
      FORCE)
    message(CHECK_PASS "found : ${IZ_MSVS_WINDOWS_SDK_ROOT}")
  endif()

  cmake_language(CALL msvs::directory IZ_MSVS_TOOLS_VERSION
    IZ_MSVS_TOOLS_VERSION
    PATH "${IZ_MSVS_INSTALL_PATH}/VC/Tools/MSVC"
    VARIABLE IZ_MSVS_TOOLSET
    DOC "MSVC Toolset")

  cmake_language(CALL msvs::directory IZ_MSVS_WINDOWS_SDK_VERSION
    PATH "${IZ_MSVS_WINDOWS_SDK_ROOT}/Include"
    VARIABLE CMAKE_SYSTEM_VERSION
    DOC "Windows SDK")

  set(windows.sdk.host "Host${CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE}")

  if(${CMAKE_VS_PLATFORM_NAME} MATCHES "x64")
    set(windows.sdk.target "x64")
  else()
    set(windows.sdk.target "x86")
  endif()

  set(msvc.tools.dir "${IZ_MSVS_INSTALL_PATH}/VC/Tools/MSVC/${IZ_MSVS_TOOLS_VERSION}")

  block(SCOPE_FOR VARIABLES)
  list(PREPEND CMAKE_SYSTEM_PROGRAM_PATH
    "${msvc.tools.dir}/bin/${windows.sdk.host}/${windows.sdk.target}"
    "${IZ_MSVS_WINDOWS_SDK_ROOT}/bin/${IZ_MSVS_WINDOWS_SDK_VERSION}/${windows.sdk.target}"
    "${IZ_MSVS_WINDOWS_SDK_ROOT}/bin")
  find_program(CMAKE_MASM_ASM_COMPILER NAMES ml64 ml DOC "MSVC ASM Compiler")
  find_program(CMAKE_CXX_COMPILER NAMES cl REQUIRED DOC "MSVC C++ Compiler")
  find_program(CMAKE_RC_COMPILER NAMES rc REQUIRED DOC "MSVC Resource Compiler")
  find_program(CMAKE_C_COMPILER NAMES cl REQUIRED DOC "MSVC C Compiler")
  find_program(CMAKE_LINKER NAMES link REQUIRED DOC "MSVC Linker")
  find_program(CMAKE_AR NAMES lib REQUIRED DOC "MSVC Archiver")
  find_program(CMAKE_MT NAMES mt REQUIRED DOC "MSVC Manifest Tool")
  endblock()
endfunction()
