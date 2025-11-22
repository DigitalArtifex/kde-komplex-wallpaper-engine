# Komplex Wallpaper Engine

<img src="https://github.com/DigitalArtifex/DigitalArtifex/blob/f3eb531a9afda9a36d5753a82974b12e54172ad2/komplex.gif" width="100%" />

Komplex Wallpaper Engine is an advanced wallpaper engine for the KDE Plasma 6 Desktop Environment that allows the use of complex shader arrangements as a Wallpaper. Shader arrangements are a collection of shaders and various channel buffers that the shader is intended to manipulate, resulting in visually stunning live motion and reactive wallpapers.

> [!NOTE]
> `api.artifex.services` is now live! Shaders, Images, Videos and Cubemaps can now be obtained with the in-app media hubs

## Supported Engine Modes
- Simple
- Komplex

### Supported Channel Buffers
- Shaders
- Images
- Videos
- Cubemaps
- Audio
- QML Scenes
- Recursive Frame Buffer

> [!IMPORTANT]
> GLSL Shaders can be manually imported but must be compiled with the `qsb` tool supplied with Qt. A tool has been provided as `~/.local/share/komplex/tools/stc.py` to assist with this process and to process shader importing. Please see the [Wiki](https://github.com/DigitalArtifex/kde-komplex-wallpaper-engine/wiki/Converting-ShaderToy-Pages-To-Komplex-Packs) for more information.

> [!IMPORTANT]
> Audio reactivity requires Pipewire be the active audio server

### Engine Mode: Simple

The **Simple** engine mode is meant to use a single generative or manipulative shader that can use up to 4 configurable channel buffers as the wallpaper. Channel buffers can be configured to be other shaders, images, videos, cubemaps, QML scenes and desktop audio capture. For video and images, you have the ability to import directly from the respective Pexels API.

### Engine Mode: Komplex

The **Komplex** engine mode allows for a much more complex wallpaper experience. Instead of a simple configuration scheme, the Komplex engine mode uses a shader pack file that can contain it's own images, cubemaps, videos and shaders. This shader pack must contain a pack.json file that describes the output shader, resolution, speed and channel buffers 0-3. Each channel buffer can have channel buffers 0-3, which can in-turn have channel buffers 0-3 and so on. This allows near infinite arrangement complexity, only limited by hardware and reasoning.

The **Komplex** engine mode also allows for direct ShaderToy importing through the use of the ShaderToy API. Most ShaderToy functionality is supported, and features a media import function when the shader uses a video as a resource.


## Installation (Release Packages)

### Arch - AUR
Use your favorite AUR helper to install `plasma6-wallpapers-komplex`.

## Post-installation
In order for the plugin to be registered with Plasma 6, we will need to restart the plasmashell session. In order for the g-streamer backend to take effect, a reboot may be required.

### Restart Plasmashell
```
systemctl --user restart plasma-plasmashell.service
```

## Installation (manual)

### Requirements
- qt6-base
- qt6-multimedia
- qt6-multimedia-gstreamer*
- qt6-declarative
- qt6-imageformats
- qt6-quick3d
- qt6-shadertools
- qt6-webview
- unzip
- ECM (extra-cmake-modules)
- plasma-desktop
- cmake

### Instructions

After ensuring your system has all the required packages, run the following commands to clone the repo and enter it's directory.
```
git clone https://github.com/DigitalArtifex/kde-komplex-wallpaper-engine.git
cd kde-komplex-wallpaper-engine
mkdir build
cmake -S ./ -B ./build
cmake --build ./build
sudo cmake --install ./build
```
The contents of data/* should be copied to the system
```
sudo mkdir /usr/share/komplex/
cp -r data/* /usr/share/komplex/
```

> [!WARNING]
> After installation, it is likely that you may experience scan lines and other artifacts when using the `Video Channel Buffer`. This is due to the default backend being FFMPEG, which is known to have such issues with Qt. You can correct this issue by using the following command to change to the `gstreamer` backend provided by qt6-multimedia-gstreamer.
> 
> `sudo echo "export QT_MEDIA_BACKEND=gstreamer" >> /etc/profile`

## Credits

This project was inspired by `KDE Shader Wallpaper`, `Wallpaper Engine` and others. It uses code that was originally part of `KDE Shader Wallpaper`.

This project uses icons donated by [Icons8](http://www.icons8.com)

Shaders provided by various artists from [ShaderToy](http://www.shadertoy.com) (API)

Image and Videos provided by [Pexels](http://www.pexels.com) (API)

To support me, this project or to find Linux themed hot sauces, you can [Buy me a coffee](https://ko-fi.com/digitalartifex)
