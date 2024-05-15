cmake_minimum_required(VERSION 3.23)

project(ocmake_util)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/Modules" "${CMAKE_CURRENT_SOURCE_DIR}/Projects")
list(REMOVE_DUPLICATES CMAKE_MODULE_PATH)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} CACHE INTERNAL "CMAKE_MODULE_PATH")
include(ProjectDefinition)
include(ProjectImport)
include(TargetImport)