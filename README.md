# Komplex Wallpaper Engine

Komplex Wallpaper Engine is an advanced wallpaper engine for the KDE Plasma 6 Desktop Environment that allows the use of complex shader arrangements as a Wallpaper. Shader arrangements are a collection of shaders and various channel buffers that the shader is intended to manipulate, resulting in visually stunning live motion and reactive wallpapers.

[![Youtube Video](https://github.com/user-attachments/assets/19196d80-0a30-4e94-9260-6e450ae0f325)](https://www.youtube.com/watch?v=qjKEwrNts1A)

## Supported Engine Modes
- ShaderToy
- Komplex

### Supported Channel Buffers
- Shaders*
- Images
- Videos
- Cubemaps**
- Audio***

*Shaders must be compiled with the `qsb` tool supplied with Qt. It may be available through your distribution's package manager. Follow the instructions in /tools/README.md to compile shaders for use with Qt.

**The Cubemaps provided in this package are released under Creative Commons Attribution 3.0 Unported License and were obtained from [Humus](http://www.humus.name)

***Audio reactivity requires KDE to be using Pipewire

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

### Requirements
- qt6-base
- qt6-multimedia
- qt6-multimedia-gstreamer*
- qt6-declarative
- qt6-imageformats
- qt6-quick3d
- qt6-shadertools
- ECM (extra-cmake-modules)
- plasma-desktop
- cmake

### Instructions

After ensuring your system has all the required packages, run the following commands
```
git clone https://github.com/DigitalArtifex/kde-komplex-wallpaper-engine.git
cd kde-komplex-wallpaper-engine
cmake -S ./ -B ./build
cmake --build ./build
cmake --install ./build
```

After installation, it is likely that you may experience scan lines and other artifacts when using the `Video Channel Buffer`. This is due to the default backend being FFMPEG, which is known to have such issues with Qt. You can correct this issue by using the `gstreamer` backend provided by qt6-multimedia-gstreamer. 
```
sudo echo "export QT_MEDIA_BACKEND=gstreamer" >> /etc/profile
```
This step is automatically executed by the Arch installation package.

## Installation (Release Packages)

Currently only Arch packages are available at this time. I am working towards Debian and Gentoo releases as well.

## Credits

This project was inspired by `KDE Shader Wallpaper`, `Wallpaper Engine` and others. It uses code that was originally part of `KDE Shader Wallpaper`.

This project uses icons donated by [Icons8](http://www.icons8.com)

To support me, this project or to find Linux themed hot sauces, you can [Buy me a coffee](https://ko-fi.com/digitalartifex)
