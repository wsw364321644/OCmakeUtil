FUNCTION(IsSHA1String inValName outValName)
    set(${outValName} FALSE PARENT_SCOPE)
    string(LENGTH "${inValName}" STR_LENGTH)

    if(STR_LENGTH EQUAL 40)
        string(REGEX MATCH "^[a-fA-F0-9]+$" MATCH_RESULT "${INPUT_GIT_TAG}")

        if(MATCH_RESULT)
            set(${outValName} TRUE PARENT_SCOPE)
        endif()
    endif()
ENDFUNCTION(IsSHA1String)