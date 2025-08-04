# Komplex Wallpaper Engine

Komplex Wallpaper Engine is an advanced wallpaper engine for the KDE Plasma 6 Desktop Environment that allows the use of complex shader arrangements as a Wallpaper. Shader arrangements are a collection of shaders and various channel buffers that the shader is intended to manipulate, resulting in visually stunning live motion and reactive wallpapers.

https://github.com/user-attachments/assets/456bedfc-1d18-4520-9340-ab7d0f0a8f98

## Supported Engine Modes
- ShaderToy
- Komplex

### Supported Channel Buffers
- Shaders*
- Images
- Videos
- Cubemaps**

*Shaders must be compiled with the `qsb` tool supplied with Qt. It may be available through your distribution's package manager. Follow the instructions in /tools/README.md to compile shaders for use with Qt.

### Engine Mode: ShaderToy

The [ShaderToy](http://www.shadertoy.com) Engine mode is designed to work with most* of the pages on [ShaderToy.com](http://www.shadertoy.com) and is the easiest to use and configure as it can be setup via the settings panel. Simply select a manipulative shader as the main output and setup the iChannels the shader supports. Try feeding it a generative shader!

*Volumetric and audio channels are not currently supported, but are in development.

ShaderToy import functionality is currently in development

### Engine Mode: Komplex

The **Komplex** engine mode allows for a much more complex wallpaper experience. Instead of a simple configuration scheme, the Komplex engine mode uses a shader pack file that can contain it's own images, cubemaps, videos and shaders. This shader pack must contain a pack.json file that describes the output shader, resolution, speed and channel buffers 0-3. Each channel buffer can have channel buffers 0-3, which can in-turn have channel buffers 0-3 and so on. This allows near infinite arrangement complexity, only limited by hardware and reasoning.

Example `pack.json` file:
```json
{
    "author": "DigitalArtifex",
    "name": "Test",
    "version": "1.0.0",
    "description": "Test",
    "license": "GPLv3+",
    "engine": "shadertoys",
    "id": "sdE3sx",

    "type": 2,
    "source": "./shaders/video-glitch-extra.frag.qsb",
    "speed": 0.14,

    "channel0":
    {
        "type": 2,
        "source": "./shaders/edge-detect-greyscale.frag.qsb",

        "resolution_x": 1920,
        "resolution_y": 1080,
        "resolution_scale": 1.0,
        "time_scale": 1.0,
        "mouse_scale": 1.0,

        "channel0":
        {
            "type": 2,
            "source": "./shaders/Glow-City.frag.qsb",

            "resolution_x": 1920,
            "resolution_y": 1080,
            "resolution_scale": 1.0,
            "time_scale": 1.0,
            "mouse_scale": 1.0
        }
    }
}
```

## Installation (manual)

Contents of the `data` directory should be placed in `~/.local/komplex/`

Compiling requires setting up the `kde-builder` package, setting the required env variables and selecting the proper CMake kit for building.

## Installation (Release Packages)

No release packages are available at this time. We are working on getting them setup for multiple package managers.

## Credits

This project was inspired by `KDE Shader Wallpaper`, `Wallpaper Engine` and others. It uses code that was originally part of `KDE Shader Wallpaper`.

This project uses icons donated by [Icons8](http://www.icons8.com)
