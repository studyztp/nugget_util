function(nugget_read_list OUT_RIDS FILE_PATH)
    set(out_list "")
    file(READ ${FILE_PATH} CONTENT)
    
    # First replace newlines with semicolons
    string(REGEX REPLACE "\n" ";" CONTENT "${CONTENT}")
    # Then split on spaces
    string(REGEX REPLACE "[ ]+" ";" CONTENT "${CONTENT}")

    foreach(ITEM ${CONTENT})
        if(NOT "${ITEM}" STREQUAL "")
            list(APPEND out_list ${ITEM})
        endif()
    endforeach()

    set(${OUT_RIDS} ${out_list} PARENT_SCOPE)
endfunction()


