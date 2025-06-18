include(FetchContent)
include(ExternalProject)

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

        fetchcontent_declare(
            ${ResourceName}
            GIT_REPOSITORY ${INPUT_GIT_REPOSITORY}
            GIT_TAG ${INPUT_GIT_TAG}
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

        fetchcontent_declare(
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