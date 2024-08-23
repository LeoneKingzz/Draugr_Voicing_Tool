# It's recommended to set a minimum CMake version.
# If you use CMake features from higher versions, update this to match.
cmake_minimum_required(VERSION 3.29)
message("Using toolchain file ${CMAKE_TOOLCHAIN_FILE}.")
########################################################################################################################
## Define project
########################################################################################################################
project(DraugrShoutVoicing
		DESCRIPTION ""
		VERSION 0.0.1
		LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_DEBUG OFF)
set(CMAKE_OPTIMIZE_DEPENDENCIES ON)

include(GNUInstallDirs)

configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/version.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/version.rc
        @ONLY)

if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
    cmake_policy(SET CMP0135 NEW)
endif()

if (POLICY CMP0141)
    cmake_policy(SET CMP0141 NEW)
    set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<IF:$<AND:$<C_COMPILER_ID:MSVC>,$<CXX_COMPILER_ID:MSVC>>,$<$<CONFIG:Debug,RelWithDebInfo>:EditAndContinue>,$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>>")
endif()

# Add headers
file(
        GLOB_RECURSE
        headers
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
)
list(REMOVE_ITEM headers ${CMAKE_CURRENT_SOURCE_DIR}/include/PCH.h)

# Add sources
file(
        GLOB_RECURSE
        sources
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc
        ${CMAKE_CURRENT_BINARY_DIR}/version.rc
)

source_group(
        TREE ${CMAKE_CURRENT_SOURCE_DIR}
        FILES
        ${headers}
        ${sources})

#########################################################################################################################
### Build options
#########################################################################################################################
message("Options:")
option(BUILD_TESTS "Build unit tests." OFF)
message("\tTests: ${BUILD_TESTS}")

########################################################################################################################
## Configure target DLL
########################################################################################################################
if(DEFINED ENV{GITHUB_ENV})
    # If running in a GitHub Actions environment, always use the submodule directory.
    set(CommonLibSSE "${CMAKE_CURRENT_SOURCE_DIR}/extern/CommonLibSSE-NG/")
elseif(DEFINED ENV{CommonLibSSEPath})
    # If CommonLibSSEPath is set, use the provided environment variable.
    set(CommonLibSSE $ENV{CommonLibSSEPath})
    message(STATUS "CommonLibSSEPath environment variable found.")
else()
    # If not in GitHub Actions and CommonLibSSEPath is not set, fallback to the submodule directory.
    set(CommonLibSSE "${CMAKE_CURRENT_SOURCE_DIR}/extern/CommonLibSSE-NG/")
    message(WARNING "CommonLibSSEPath not defined. Using submodule directory: ${CommonLibSSE}")
    message(WARNING "Ensure that the CommonLibSSE-NG submodule is initialized.")
endif()

if(NOT DEFINED CommonLibSSE)
    message(FATAL_ERROR "Variable CommonLibSSE is not Defined.Make sure to define it")
endif()

add_subdirectory(${CommonLibSSE} CommonLibSSE-NG)
include(${CommonLibSSE}/cmake/CommonLibSSE.cmake)

find_path(CLIB_UTIL_INCLUDE_DIRS "ClibUtil/utils.hpp")

add_commonlibsse_plugin(${PROJECT_NAME} SOURCES ${headers} ${sources}) # <--- specifies plugin.cpp

target_include_directories(${PROJECT_NAME}
        PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/src>
        $<INSTALL_INTERFACE:src>
        nlohmann_json::nlohmann_json
        ${CLIB_UTIL_INCLUDE_DIRS})

target_include_directories(${PROJECT_NAME}
        PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

target_precompile_headers(${PROJECT_NAME}
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include/PCH.h)

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

install(TARGETS ${PROJECT_NAME}
        DESTINATION "${CMAKE_INSTALL_LIBDIR}")

########################################################################################################################
## Automatic plugin deployment
########################################################################################################################
# Automatic deployment to Mod Organizer 2 mod directory.
foreach(DEPLOY_TARGET $ENV{SkyrimPluginTargets})
    set(DEPLOY_TARGET_COMMON_DIR "${DEPLOY_TARGET}/${PROJECT_NAME} - ${CMAKE_BUILD_TYPE}/SKSE/Plugins/")
    message("Adding deployment target ${DEPLOY_TARGET}.")

    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${DEPLOY_TARGET_COMMON_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:${PROJECT_NAME}>" "${DEPLOY_TARGET_COMMON_DIR}")

    if(${CMAKE_BUILD_TYPE} STREQUAL Debug OR ${CMAKE_BUILD_TYPE} STREQUAL RelWithDebInfo)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_PDB_FILE:${PROJECT_NAME}>" "${DEPLOY_TARGET_COMMON_DIR}")
    endif()
endforeach()
