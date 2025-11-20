#  Komplex Wallpaper Engine
#  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
#
#  ShaderToyProcessor.py
#
#  This file is used to convert the shaders in a shadertoy entry to a Komplex wallpaper
#  package. It is designed to automate the process of preparing and compiling the shader
#  files.
#
#  The process is as follows:
#  1) Process the Common.frag file, if it exists
#  2) Read in the source file (.frag)
#  3) Append the Common.frag file, if it exists
#  4) Save file as `Name.tmp` into the temp directory
#  5) Process `Name.tmp` with `cpp -P`, outputting it as `Name.frag`
#  6) Delete the temp file
#  7) Prepare `Name.frag` by adding ubuf struct and version info
#  8) Replace known buffer calls to their ubuf equivalent
#  9) Compile `Name.frag`
#  10) Copy non-shader files
#
#  This expanded process covers the following caveats of the original script:
#  1) when ubuf member names are used in Common file functions.
#  ==== For instance, if the creator used iTime as a function variable
#       this script renames the variable to _iTime
#  2) alters macro expansion to allow ill-formed macro use
#  ==== Macros that take arguments, but don't have arguments in use would cause errors
#
#  Usage:
#  python ShaderToyProcessor.py [options] -i input_directory [-o output_dirctory] [-t temp_directory]
# 
#  This file uses code that was originally part of the KDE Shader Wallpaper Project.
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>

import os
import re
import shutil
import argparse
import sys
import subprocess
import traceback

# Specify the directory where your .frag files are located
source_directory = 'src'
temp_directory = 'packs_processed'
output_directory = 'build'
dirname = ''

DELETE_AFTER_COMPILATION = False

# List of variables to update
variables_to_update = [
    'iTime', 'iTimeDelta', 'iFrameRate', 'iSampleRate',
    'iFrame', 'iDate', 'iMouse', 'iResolution',
    r'iChannelTime', r'iChannelResolution'
]

# Header to be prepended to the shader file
# do not include the version declarative
header = '''#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float iTime;
    float iTimeDelta;
    float iFrameRate;
    float iSampleRate;
    int iFrame;
    vec4 iDate;
    vec4 iMouse;
    vec3 iResolution;
    float iChannelTime[4];
    vec3 iChannelResolution[4];
} ubuf;

layout(binding = 1) uniform sampler2D iChannel0;
layout(binding = 2) uniform sampler2D iChannel1;
layout(binding = 3) uniform sampler2D iChannel2;
layout(binding = 4) uniform sampler2D iChannel3;

vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * ubuf.iResolution.xy;
'''

# Footer to be appended, containing the main entry point
footer = '''
void main() {
    vec4 color = vec4(0.0);
    mainImage(color, fragCoord);
    fragColor = color;
}
'''

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='A shader processor for ShaderToy',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python ShaderToyProcessor.py -i ./src/deadly_halftones
        """
    )
    
    parser.add_argument('-i', '--input', 
                       help='Input directory to process',
                       required=True)
    
    parser.add_argument('-v', '--verbose', 
                       action='store_true', 
                       help='Enable verbose output')
    
    parser.add_argument('-o', '--output', 
                       default='packs_build', 
                       help='Output Directory')
    
    parser.add_argument('-t', '--temp', 
                       default='packs_processed', 
                       help='Temporary Files Directory')
    
    parser.add_argument('-q', '--qsb', 
                       default='/usr/lib/qt6/bin/qsb', 
                       help='Path to QSB Compiler')
    
    return parser.parse_args()

#  9) Compile `Name.frag`
#  10) Copy non-shader files
def compile():
    args = parse_arguments()

    if args.input:
        source_directory = args.input

    dirname = os.path.basename(source_directory)

    qsb = args.qsb
    output_directory = args.output + '/' + dirname
    source_directory = temp_directory + '/' + dirname
    
    if args.verbose:
        print(f"Compiling: {source_directory}")
        print(f"Output directory: {output_directory}")

    last_file = ""
    last_dir = ""

    # Ensure output directory exists
    os.makedirs(output_directory, exist_ok=True)

    # Iterate over all .frag files in the source directory
    for root, dirs, files in os.walk(source_directory):
        try:
            last_dir = root

            for file in files:
                if file.endswith('.frag') and not file == 'Common.frag':
                    last_file = file

                    # Construct the full path to the source file
                    source_file_path = os.path.join(root, file)
                    
                    # Construct new output path
                    relative_path = os.path.relpath(root, source_directory)
                    new_root = os.path.join(output_directory, relative_path)
                    os.makedirs(new_root, exist_ok=True)
                    
                    output_file_name = file.replace('.frag', '.frag.qsb')
                    output_file_path = os.path.join(new_root, output_file_name)

                    # Construct and execute the command
                    cmd = [
                        qsb, '--glsl', '330 es,330,320 es,320', '--hlsl', '50', '--msl', '12',
                        '-o', output_file_path, source_file_path
                    ]

                    subprocess.run(cmd, check=True)
                    # If the command was successful, delete the source file
                    if (DELETE_AFTER_COMPILATION):
                        os.remove(source_file_path)
                        if args.verbose:
                            print(f"Successfully converted and deleted: {file}")
                    elif args.verbose:
                        print(f"--Successfully compiled: {file}")

                # Otherwise, just copy the file
                else:
                    file_path = os.path.join(root, file)
                    
                    # Construct new output path
                    relative_path = os.path.relpath(root, source_directory)
                    new_root = os.path.join(output_directory, relative_path)
                    os.makedirs(new_root, exist_ok=True)
                    new_file_path = os.path.join(new_root, file)

                    if args.verbose:
                        print(f"--Writing to: '{new_file_path}'")

                    shutil.copy(file_path, new_file_path)

        except subprocess.CalledProcessError:
            # If the command failed, do not delete the source file
            print(f"Compiling failed for: {last_file}")
            print(f"Deleting: {last_dir}")
            shutil.rmtree(last_dir)
            # sys.exit(1)
        except FileNotFoundError:
            print(f"Error: Directory '{args.input}' not found")
            shutil.rmtree(last_dir)
            # sys.exit(1)
        except PermissionError:
            print(f"Error: Permission denied: '{args.input}'")
            shutil.rmtree(last_dir)
            # sys.exit(1)
        except Exception as e:
            print(traceback.format_exc())
            shutil.rmtree(last_dir)
            # sys.exit(1)

#  1) Process the Common.frag file, if it exists
#  2) Read in the source file (.frag)
#  3) Append the Common.frag file, if it exists
#  4) Save file as `Name.tmp` into the temp directory
#  5) Process `Name.tmp` with `cpp -P`, outputting it as `Name.frag`
#  6) Delete the temp file
#  10) Copy non-shader files
def process():
    args = parse_arguments()

    if args.temp:
        temp_directory = args.temp

    if args.input:
        source_directory = args.input
    else:
        print(f"No input directory given")
        sys.exit(1)
    
    if args.verbose:
        print(f"Processing: {source_directory}")
        print(f"--Output directory: {temp_directory}")

    last_file = ""
    last_dir = ""

    for root, dirs, files in os.walk(source_directory):
        try:

            last_dir = root

            # Grab the Common shader file, if it exists
            common_file_path = os.path.join(root, 'Common.frag')
            common_file_contents = ""

            if os.path.exists(common_file_path):
                with open(common_file_path, 'r') as f:
                    common_file_contents = f.read()
                
            # 1. Remove any existing #version directive to avoid conflicts
            common_file_contents = re.sub(r'^\s*#version\s+.*?\n', '', common_file_contents, flags=re.MULTILINE)

            # 2. Remove any pre-existing main() function
            common_file_contents = re.sub(r'void\s+main\s*\([^)]*\)\s*\{[\s\S]*?\}', '', common_file_contents)

            # 3. Remove declarations in the common file that match the replacement vars
            # -- This really needs to be moved into a detection function that checks for 
            # -- ubuf names within function scopes. This is messing with correctly formatted
            # -- defines in the common file
            
            # for var in variables_to_update:
            #     pattern = r'(\w*\s*)(' + var + ')'
            #     replacement = r'\1_\2'

            #     common_file_contents = re.sub(pattern, replacement, common_file_contents)
                
            for file in files:# Stage for processing, if a shader
                if file.endswith('.frag') and not file == 'Common.frag':
                    last_file = file
                    file_path = os.path.join(root, file)

                    if args.verbose:
                        print(f"--Preparing: {file}")
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # 1. Remove any existing #version directive to avoid conflicts
                    content = re.sub(r'^\s*#version\s+.*?\n', '', content, flags=re.MULTILINE)

                    # 2. Remove any pre-existing main() function
                    content = re.sub(r'void\s+main\s*\([^)]*\)\s*\{[\s\S]*?\}', '', content)

                    # 4. Assemble the final, complete shader
                    final_content = common_file_contents.strip() + '\n' + content.strip()

                    # Construct new output path
                    base_name, old_name = os.path.splitext(file)

                    relative_path = os.path.relpath(root, os.path.dirname(source_directory))
                    new_root = os.path.join(temp_directory, relative_path)
                    os.makedirs(new_root, exist_ok=True)
                    new_file_path = os.path.join(new_root, base_name + '.tmp')

                    if args.verbose:
                        print(f"--Writing to: '{new_file_path}'")

                    # Write to the new file
                    with open(new_file_path, 'w', encoding='utf-8') as f:
                        f.write(final_content)

                    # Process file with cpp
                    prepared_file_path = os.path.join(new_root, file)

                    if args.verbose:
                        print(f"--Processing to: '{prepared_file_path}'")

                    # Construct the command
                    cmd = [
                        'cpp', '-P', '-C', new_file_path, prepared_file_path
                    ]
                    
                    subprocess.run(cmd, check=True)
                    os.remove(new_file_path) #remove the temp file
                    
                # Otherwise, just copy the file
                elif not file == 'Common.frag':
                    file_path = os.path.join(root, file)

                    # Construct new output path
                    relative_path = os.path.relpath(root, os.path.dirname(source_directory))
                    new_root = os.path.join(temp_directory, relative_path)
                    os.makedirs(new_root, exist_ok=True)
                    new_file_path = os.path.join(new_root, file)

                    if args.verbose:
                        print(f"--Writing to: '{new_file_path}'")

                    shutil.copy(file_path, new_file_path)

        except subprocess.CalledProcessError:
            # If the command failed, do not delete the source file
            print(f"Compiling failed for: {last_file}")
            shutil.rmtree(last_dir)
            # sys.exit(1)
        except FileNotFoundError:
            print(f"Error: Directory '{args.input}' not found")
            shutil.rmtree(last_dir)
            # sys.exit(1)
        except PermissionError:
            print(f"Error: Permission denied: '{args.input}'")
            shutil.rmtree(last_dir)
            # sys.exit(1)
        except Exception as e:
            print(traceback.format_exc())
            shutil.rmtree(last_dir)
            # sys.exit(1)


#  7) Prepare `Name.frag` by adding ubuff struct and version info
#  8) Replace known buffer calls to their ubuff equivalent
#  10) Copy non-shader files
def prepare():
    args = parse_arguments()

    if args.temp:
        temp_directory = args.temp
    
    if args.verbose:
        print(f"Preparing: {temp_directory}")
    
    last_file = ""
    last_dir = "" # track for deleting

    for root, dirs, files in os.walk(temp_directory):
        try:
            last_file = root
            for file in files:

                # Stage for compiling, if a shader
                if file.endswith('.frag') and not file == 'Common.frag':
                    last_file = file
                    file_path = os.path.join(root, file)

                    if args.verbose:
                        print(f"--Preparing: {file}")
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()

                        # 1. Remove any existing #version directive to avoid conflicts
                        content = re.sub(r'^\s*#version\s+.*?\n', '', content, flags=re.MULTILINE)

                        # 2. Remove any pre-existing main() function
                        content = re.sub(r'void\s+main\s*\([^)]*\)\s*\{[\s\S]*?\}', '', content)

                        # 3. Prepend 'ubuf.' to all shadertoy uniforms
                        for var in variables_to_update:
                            pattern = r'(?<!\w)' + var
                            replacement = 'ubuf.' + var
                            content = re.sub(pattern, replacement, content)

                        # 4. Assemble the final, complete shader
                        final_content = header + '\n' + content.strip() + '\n' + footer

                        # Write to the new file
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(final_content)

        except subprocess.CalledProcessError:
            # If the command failed, do not delete the source file
            print(f"Compiling failed for: {last_file}")
            # shutil.rmtree(last_dir)
            # sys.exit(1)
        except FileNotFoundError:
            print(f"Error: Directory '{args.input}' not found")
            # shutil.rmtree(last_dir)
            # sys.exit(1)
        except PermissionError:
            print(f"Error: Permission denied: '{args.input}'")
            # shutil.rmtree(last_dir)
            # sys.exit(1)
        except Exception as e:
            print(traceback.format_exc())
            # shutil.rmtree(last_dir)
            # sys.exit(1)


if __name__ == '__main__':
    process()
    prepare()
    compile()
