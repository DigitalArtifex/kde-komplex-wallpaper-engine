# This file was originally part of the KDE Shader Wallpaper Project
# it contains modifications from Neil Panda and myself

import os
import sys
import subprocess
import shutil
import argparse

# THIS WILL DELETE YOUR ORIGINAL FRAG AFTER COMPILING IF SET TO TRUE
DELETE_AFTER_COMPILATION = False

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
                       default='processed', 
                       help='Input directory to process')
    
    parser.add_argument('-v', '--verbose', 
                       action='store_true', 
                       help='Enable verbose output')
    
    parser.add_argument('-o', '--output', 
                       default='build', 
                       help='Output Directory')
    
    return parser.parse_args()

def main():
    args = parse_arguments()

    if args.output:
        output_directory = args.output

    if args.input:
        source_directory = args.input
    
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


if __name__ == '__main__':
    main()
