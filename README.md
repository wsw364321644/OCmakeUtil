# OCmakeUtil
afford cmake help function to build project convenience.
## Import External Project
```
set(PROJECT_STATIC_CRT OFF)

if(PROJECT_STATIC_CRT)
  set(STATIC_CRT STATIC_CRT)
else()
  unset(STATIC_CRT)
endif()

set(GIT_SSH OFF)

if(GIT_SSH)
  set(SSH SSH)
else()
  unset(SSH)
endif()

ImportProject(ZLIB STATIC ${STATIC_CRT} ${SSH} FIND TAG v1.3.2)
ImportProject(OpenSSL STATIC ${STATIC_CRT} ${SSH} FIND TAG openssl-3.6.1)
ImportProject(SQLite3 ${STATIC_CRT} URL https://sqlite.org/2026/sqlite-amalgamation-3510300.zip)
ImportProject(libuv ${STATIC_CRT} ${SSH} TAG v1.52.1)
ImportProject(CURL ${STATIC_CRT} STATIC ${SSH} TAG curl-8_18_0)
```
## Define Libarary
```
NewTargetSource()
AddSourceFolder(INCLUDE RECURSE PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/public")
AddSourceFolder(RECURSE "${CMAKE_CURRENT_SOURCE_DIR}/private")
add_library(${TARGET_NAME} SHARED ${SourceFiles})
AddTargetInclude(${TARGET_NAME})
add_library(${PROJECT_NAME}::${TARGET_NAME} ALIAS ${TARGET_NAME})
if(NOT DISABLE_INSTALL)
    AddTargetInstall(${TARGET_NAME} ${PROJECT_NAME})
endif()
```
