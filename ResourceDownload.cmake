include(FetchContent)
include(ExternalProject)
include(RegexHelper)

FUNCTION(ResourceDownload ResourceName)
    set(options)
    set(oneValueArgs URL URL32 GIT_REPOSITORY GIT_TAG)
    set(multiValueArgs)

    cmake_parse_arguments(INPUT "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN})

    if(INPUT_GIT_REPOSITORY)
        if(NOT INPUT_GIT_TAG)
            message(FATAL_ERROR "GIT_TAG is required for ${ResourceName} download")
        endif()

        IsSHA1String(INPUT_GIT_TAG BGIT_TAG_SHA1)

        if(BGIT_TAG_SHA1)
            set(GIT_SHALLOW_VAL FALSE)
        else()
            set(GIT_SHALLOW_VAL TRUE)
        endif()

        message(STATUS "Downloading ${ResourceName} from ${INPUT_GIT_REPOSITORY} GIT_TAG ${INPUT_GIT_TAG}")
        FetchContent_Declare(
            ${ResourceName}
            GIT_REPOSITORY ${INPUT_GIT_REPOSITORY}
            GIT_TAG ${INPUT_GIT_TAG}
            GIT_SUBMODULES ""
            GIT_SHALLOW ${GIT_SHALLOW_VAL}
        )
        FetchContent_Populate(${ResourceName})

    else()
        if(NOT INPUT_URL)
            if(NOT INPUT_URL32)
                message(FATAL_ERROR "URL is required for ${ResourceName} download")
            else()
                set(URL ${INPUT_URL32})
            endif()
        else()
            if(NOT INPUT_URL32)
                set(URL ${INPUT_URL})
            else()
                cmake_host_system_information(RESULT HOST_IS_64BIT QUERY IS_64BIT)

                if(${HOST_IS_64BIT})
                    set(URL ${INPUT_URL})
                else()
                    set(URL ${INPUT_URL32})
                endif()
            endif()
        endif()

        FetchContent_Declare(
            ${ResourceName}
            URL ${URL}
            DOWNLOAD_NO_EXTRACT false
            DOWNLOAD_EXTRACT_TIMESTAMP false
        )
        FetchContent_MakeAvailable(${ResourceName})
    endif()

    FetchContent_GetProperties(${ResourceName})
    string(TOLOWER ${ResourceName} ResourceName_Lower)
    set(${ResourceName}_DIR ${${ResourceName_Lower}_SOURCE_DIR} PARENT_SCOPE)
ENDFUNCTION(ResourceDownload)