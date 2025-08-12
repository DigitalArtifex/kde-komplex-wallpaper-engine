# This file was originally part of the KDE Shader Wallpaper Project

import os
import re
import shutil
import argparse
import sys
import subprocess

# Specify the directory where your .frag files are located
source_directory = 'src'
temp_directory = 'processed'
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
                       help='Input directory to process')
    
    parser.add_argument('-v', '--verbose', 
                       action='store_true', 
                       help='Enable verbose output')
    
    parser.add_argument('-o', '--output', 
                       default='build', 
                       help='Output Directory')
    
    parser.add_argument('-t', '--temp', 
                       default='processed', 
                       help='Temporary Files Directory')
    
    return parser.parse_args()

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
        print(f"Input directory: {source_directory}")
        print(f"Output directory: {temp_directory}")
    
    try:
        for root, dirs, files in os.walk(source_directory):

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

            # 3. Prepend 'ubuf.' to all shadertoy uniforms
            for var in variables_to_update:
                pattern = r'(?<!\.)\b' + var + r'\b'
                replacement = 'ubuf.' + var
                common_file_contents = re.sub(pattern, replacement, common_file_contents)
            
            for file in files:

                # Stage for compiling, if a shader
                if file.endswith('.frag') and not file == 'Common.frag':
                    file_path = os.path.join(root, file)

                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()

                        # 1. Remove any existing #version directive to avoid conflicts
                        content = re.sub(r'^\s*#version\s+.*?\n', '', content, flags=re.MULTILINE)

                        # 2. Remove any pre-existing main() function
                        content = re.sub(r'void\s+main\s*\([^)]*\)\s*\{[\s\S]*?\}', '', content)

                        # 3. Prepend 'ubuf.' to all shadertoy uniforms
                        for var in variables_to_update:
                            pattern = r'(?<!\.)\b' + var + r'\b'
                            replacement = 'ubuf.' + var
                            content = re.sub(pattern, replacement, content)

                        # 4. Assemble the final, complete shader
                        final_content = header + '\n' + common_file_contents.strip() + '\n' + content.strip() + '\n' + footer

                        # Construct new output path
                        relative_path = os.path.relpath(root, os.path.dirname(source_directory))
                        new_root = os.path.join(temp_directory, relative_path)
                        os.makedirs(new_root, exist_ok=True)
                        new_file_path = os.path.join(new_root, file)

                        if args.verbose:
                            print(f"Writing to: '{new_file_path}'")

                        # Write to the new file
                        with open(new_file_path, 'w', encoding='utf-8') as f:
                            f.write(final_content)
                
                # Otherwise, just copy the file
                elif not file == 'Common.frag':
                    file_path = os.path.join(root, file)

                    # Construct new output path
                    relative_path = os.path.relpath(root, os.path.dirname(source_directory))
                    new_root = os.path.join(temp_directory, relative_path)
                    os.makedirs(new_root, exist_ok=True)
                    new_file_path = os.path.join(new_root, file)

                    if args.verbose:
                        print(f"Writing to: '{new_file_path}'")

                    shutil.copy(file_path, new_file_path)

    except FileNotFoundError:
        print(f"Error: Directory '{args.input}' not found")
        sys.exit(1)
    except PermissionError:
        print(f"Error: Permission denied: '{args.input}'")
        sys.exit(1)

def compile():
    args = parse_arguments()

    if args.input:
        source_directory = args.input

    dirname = os.path.basename(source_directory)

    if args.output:
        output_directory = args.output + '/' + dirname

    source_directory = temp_directory + '/' + dirname
    
    if args.verbose:
        print(f"Input directory: {source_directory}")
        print(f"Output directory: {output_directory}")

    last_file = ""

    # Ensure output directory exists
    os.makedirs(output_directory, exist_ok=True)

    try:
        # Iterate over all .frag files in the source directory
        for root, dirs, files in os.walk(source_directory):
            for file in files:
                if file.endswith('.frag'):
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
                        '/usr/lib/qt6/bin/qsb', '--glsl', '330', '--hlsl', '50', '--msl', '12',
                        '-o', output_file_path, source_file_path
                    ]

                    subprocess.run(cmd, check=True)
                    # If the command was successful, delete the source file
                    if (DELETE_AFTER_COMPILATION):
                        os.remove(source_file_path)
                        if args.verbose:
                            print(f"Successfully converted and deleted: {file}")
                    elif args.verbose:
                        print(f"Successfully converted: {file}")

                # Otherwise, just copy the file
                else:
                    file_path = os.path.join(root, file)
                    
                    # Construct new output path
                    relative_path = os.path.relpath(root, source_directory)
                    new_root = os.path.join(output_directory, relative_path)
                    os.makedirs(new_root, exist_ok=True)
                    new_file_path = os.path.join(new_root, file)

                    if args.verbose:
                        print(f"Writing to: '{new_file_path}'")

                    shutil.copy(file_path, new_file_path)

    except subprocess.CalledProcessError:
        # If the command failed, do not delete the source file
        print(f"Conversion failed for: {last_file}")
        sys.exit(1)
    except FileNotFoundError:
        print(f"Error: Directory '{args.input}' not found")
        sys.exit(1)
    except PermissionError:
        print(f"Error: Permission denied: '{args.input}'")
        sys.exit(1)

if __name__ == '__main__':
    process()
    compile()
