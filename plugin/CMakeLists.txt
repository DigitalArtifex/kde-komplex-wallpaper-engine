set(QML_IMPORT_PATH ${CMAKE_SOURCE_DIR}/plugin ${CMAKE_BINARY_DIR}/imports CACHE STRING "" FORCE)

set(BUILD_QML ON CACHE BOOL "")

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

add_library(
    ${PROJECT_NAME}
    SHARED
        plugin.cpp
        ShaderPackModel.cpp
        AudioModel.cpp
        AudioImageProvider.cpp
        ShaderPackMetadata.cpp
        GeometryProvider.cpp
        GeometryProvider.h
        PexelsImageMetadata.h
        PexelsImageSearch.h
        PexelsImageSearch.cpp
        PexelsVideoMetadata.h
        PexelsVideoModel.h
        PexelsVideoModel.cpp
        PexelsVideoSearch.h
        PexelsVideoSearch.cpp
        ShaderToyMetadata.h
        ShaderToySearchModel.h
        ShaderToySearchModel.cpp
        ShaderToyAPI.h
        PexelsAPI.h
) 

qt_add_qml_module(
    ${PROJECT_NAME}
    URI 
        ${QMLPLUGIN_URI}
    VERSION
        1.0
    PLUGIN_TARGET
        ${PROJECT_NAME}
    CLASS_NAME
        KomplexPlugin
    SOURCES
        plugin.cpp
        ShaderPackModel.cpp
        AudioModel.cpp
        AudioImageProvider.cpp
        ShaderPackMetadata.cpp
        GeometryProvider.cpp
        GeometryProvider.h
        PexelsImageMetadata.h
        PexelsImageSearch.h
        PexelsImageSearch.cpp
        PexelsVideoMetadata.h
        PexelsVideoModel.h
        PexelsVideoModel.cpp
        PexelsVideoSearch.h
        PexelsVideoSearch.cpp
        ShaderToyMetadata.h
        ShaderToySearchModel.h
        ShaderToySearchModel.cpp
        ShaderToyAPI.h
        PexelsAPI.h
    NO_GENERATE_PLUGIN_SOURCE
)

target_link_libraries(
    ${PROJECT_NAME}
    PRIVATE
        Qt6::Quick
        Qt6::Core
        Qt6::Gui
        Qt6::Quick3D
        Qt6::Multimedia
        Qt6::Qml
        KF6::CoreAddons
        KF6::I18n
        KF6::Package
        PipeWire::PipeWire
        fftw3
)

target_compile_definitions(
    ${PROJECT_NAME}
    PUBLIC
        KOMPLEX_PLUGIN
)

ecm_finalize_qml_module(komplex)

install(
    TARGETS 
        ${PROJECT_NAME}

    DESTINATION 
        ${KDE_INSTALL_QMLDIR}/${QMLPLUGIN_INSTALL_URI}

    LIBRARY DESTINATION
        ${KDE_INSTALL_LIBDIR}
)

set_target_properties(${PROJECT_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-Wl,--exclude-libs,ALL")