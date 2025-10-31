#!/usr/bin/env python3
"""
Convert Verilog .mem file to Xilinx .coe format for BRAM initialization
Usage: python mem_to_coe.py input.mem output.coe
"""

import sys
import re

def mem_to_coe(input_file, output_file):
    """
    Convert .mem format to .coe format
    
    .mem format:
        @0000
        0001 0002 0003
        @0100
        ABCD BEEF
    
    .coe format:
        memory_initialization_radix=16;
        memory_initialization_vector=
        0001,0002,0003,ABCD,BEEF;
    """
    
    print(f"Converting {input_file} to {output_file}...")
    
    data_values = []
    current_address = 0
    
    with open(input_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            
            # Skip empty lines and comments
            if not line or line.startswith('#') or line.startswith('//'):
                continue
            
            # Check for address directive
            if line.startswith('@'):
                addr_str = line[1:].strip()
                try:
                    current_address = int(addr_str, 16)
                    print(f"  Address section @{addr_str} at line {line_num}")
                except ValueError:
                    print(f"  Warning: Invalid address '{addr_str}' at line {line_num}")
                continue
            
            # Extract hex values from line
            hex_values = re.findall(r'[0-9A-Fa-f]+', line)
            
            for val in hex_values:
                # Pad to 4 digits (16-bit values)
                padded_val = val.upper().zfill(4)
                data_values.append(padded_val)
    
    print(f"  Extracted {len(data_values)} data values")
    
    # Write .coe file
    with open(output_file, 'w') as f:
        f.write('memory_initialization_radix=16;\n')
        f.write('memory_initialization_vector=\n')
        
        # Write values (comma-separated, last one with semicolon)
        for i, val in enumerate(data_values):
            if i < len(data_values) - 1:
                f.write(f'{val},\n')
            else:
                f.write(f'{val};')
    
    print(f"✓ Successfully created {output_file}")
    print(f"  Total memory words: {len(data_values)}")
    print(f"  Memory size: {len(data_values) * 2} bytes")
    
    return len(data_values)

def main():
    if len(sys.argv) != 3:
        print("Usage: python mem_to_coe.py input.mem output.coe")
        print("\nExample:")
        print("  python mem_to_coe.py test_data/complex_graph_memory.mem test_data/graph.coe")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        mem_to_coe(input_file, output_file)
    except FileNotFoundError:
        print(f"Error: Could not find file '{input_file}'")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
