# OCmakeUtil
afford cmake help function to build project convenience.
## Import External Project
```
  ImportProject(ZLIB STATIC_CRT STATIC TAG 09155eaa2f9270dc4ed1fa13e2b4b2613e6e4851) # 1.3
  ImportProject(SQLite3 STATIC_CRT STATIC URL https://www.sqlite.org/2023/sqlite-amalgamation-3430200.zip)
  ImportProject(LIBUV STATIC_CRT TAG be6b81a352d17513c95be153afcb3148f1a451cd) # 1.47.0
  ImportProject(CURL STATIC_CRT STATIC TAG 45d2ff6f8521524cbfa22e8be6a71a55578ccc4c) # 8.4.0
```
## Define Libarary
```
NewTargetSource()
AddSourceFolder(INCLUDE RECURSE PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/public")
AddSourceFolder(RECURSE "${CMAKE_CURRENT_SOURCE_DIR}/private")
add_library(${TARGET_NAME} SHARED ${SourceFiles})
AddTargetInclude(${TARGET_NAME})
```
