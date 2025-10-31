# Quick PYNQ-Z2 Project Creation Script
# Works without board files - just uses part number
# Run: vivado -mode gui -source create_pynq_project.tcl

set project_name "BFS_Accelerator_PYNQ"
set project_dir "./vivado_project"

# PYNQ-Z2 part number (don't need board files)
set part_name "xc7z020clg400-1"

puts "=========================================="
puts "Creating PYNQ-Z2 Project..."
puts "Part: $part_name"
puts "=========================================="

# Create project
create_project $project_name $project_dir -part $part_name -force

puts "✓ Project created successfully!"
puts ""
puts "Next steps:"
puts "  1. Add Sources → Add your RTL files from rtl/ folder"
puts "  2. Add Constraints → Add timing.xdc"
puts "  3. Create Block Design → Add Zynq PS + your module"
puts "  4. Run synthesis and implementation"
puts ""
puts "Opening project..."
