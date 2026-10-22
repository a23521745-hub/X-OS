cmake_minimum_required(VERSION 3.22)

project(X-OS
    VERSION 0.1.0
    DESCRIPTION "X-OS — Debian Stable tabanlı, PlasmaX (Wayland) arayüzlü işletim sistemi"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

include(CTest)
option(XOS_BUILD_SHELL "PlasmaX shell uygulamasını derle" ON)
option(XOS_WARNINGS_AS_ERRORS "Uyarıları hata say" OFF)

if(XOS_BUILD_SHELL)
    find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 DBus)

    # Optional: real wlr-layer-shell placement for panel windows.
    find_package(LayerShellQt QUIET CONFIG)

    qt_add_executable(plasmex
        shell/src/main.cpp
        shell/src/xosapi.h
        shell/src/xosapi.cpp
        shell/src/desktopapps.h
        shell/src/desktopapps.cpp
        shell/src/settingsstore.h
        shell/src/settingsstore.cpp
        shell/src/systemstatus.h
        shell/src/systemstatus.cpp
        shell/src/xdefender.h
        shell/src/xdefender.cpp
        shell/src/iconprovider.h
        shell/src/iconprovider.cpp
    )
    target_include_directories(plasmex PRIVATE shell/src)
    target_compile_definitions(plasmex PRIVATE XOS_VERSION="${PROJECT_VERSION}")

    if(XOS_WARNINGS_AS_ERRORS)
        target_compile_options(plasmex PRIVATE -Wall -Wextra -Werror)
    else()
        target_compile_options(plasmex PRIVATE -Wall -Wextra)
    endif()

    if(LayerShellQt_FOUND)
        target_link_libraries(plasmex PRIVATE LayerShellQt::Shell)
        target_compile_definitions(plasmex PRIVATE XOS_WITH_LAYERSHELL)
        message(STATUS "LayerShellQt bulundu — panel pencereleri layer-shell ile yerleştirilecek")
    else()
        message(STATUS "LayerShellQt yok — tam ekran fallback kullanılacak")
    endif()

    target_link_libraries(plasmex PRIVATE
        Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::DBus)

    # ── resources ────────────────────────────────────────────────────────────
    # FILES entries must be relative to CMAKE_CURRENT_SOURCE_DIR.
    file(GLOB_RECURSE XOS_QML_FILES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/shell/qml/*.qml")
    set(XOS_QML_DIRS
        shell/qml/qmldir
        shell/qml/PlasmaX/qmldir)

    file(GLOB XOS_BRANDING RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/design/branding/*.svg"
        "${CMAKE_CURRENT_SOURCE_DIR}/design/branding/*.png")

    qt_add_resources(plasmex "shell_qml"
        PREFIX "/plasmx"
        BASE "shell/qml"
        FILES ${XOS_QML_FILES} ${XOS_QML_DIRS})

    qt_add_resources(plasmex "shell_branding"
        PREFIX "/plasmx"
        BASE "design/branding"
        FILES ${XOS_BRANDING})

    install(TARGETS plasmex RUNTIME DESTINATION bin)
    qt_finalize_executable(plasmex)
endif()

# ── tests ────────────────────────────────────────────────────────────────────
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/shell/tests/CMakeLists.txt")
    add_subdirectory(shell/tests)
endif()
