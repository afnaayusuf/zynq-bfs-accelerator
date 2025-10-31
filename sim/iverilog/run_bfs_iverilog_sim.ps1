################################################################################
# Complete BFS Accelerator Simulation Script for Icarus Verilog + GTKWave
# PowerShell Version for Windows
# =========================================================================
# This script compiles and simulates the entire BFS system with graph data
# Usage: .\run_bfs_iverilog_sim.ps1
################################################################################

Write-Host "╔═════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  BFS Accelerator - Icarus Verilog Simulation Script        ║" -ForegroundColor Blue
Write-Host "╚═════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Get project root directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..\..") | Select-Object -ExpandProperty Path
$SimDir = Join-Path $ProjectRoot "sim\iverilog"

Write-Host "[1/4] Preparing simulation directory..." -ForegroundColor Yellow
if (-not (Test-Path $SimDir)) {
    New-Item -ItemType Directory -Path $SimDir -Force | Out-Null
}
Set-Location $SimDir

# Check if test data exists
$GraphMemFile = Join-Path $ProjectRoot "test_data\complex_graph_memory.mem"
if (-not (Test-Path $GraphMemFile)) {
    Write-Host "✗ Error: Graph memory file not found!" -ForegroundColor Red
    Write-Host "  Expected: $GraphMemFile" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Graph data found" -ForegroundColor Green

# Check if Icarus Verilog is installed
$IverilogPath = Get-Command iverilog -ErrorAction SilentlyContinue
if (-not $IverilogPath) {
    Write-Host ""
    Write-Host "✗ Error: Icarus Verilog (iverilog) not found in PATH!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Icarus Verilog:" -ForegroundColor Yellow
    Write-Host "  1. Download from: http://bleyer.org/icarus/" -ForegroundColor Cyan
    Write-Host "  2. Or use: winget install IcarusVerilog" -ForegroundColor Cyan
    Write-Host "  3. Add installation directory to PATH" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Compile with Icarus Verilog
Write-Host ""
Write-Host "[2/4] Compiling RTL with Icarus Verilog..." -ForegroundColor Yellow

$FilelistPath = Join-Path $SimDir "filelist_iverilog.f"
$OutputVVP = Join-Path $SimDir "bfs_system_sim.vvp"
$IncludePath1 = Join-Path $ProjectRoot "rtl\packages"
$IncludePath2 = Join-Path $ProjectRoot "rtl"

# Run iverilog
& iverilog -g2012 `
    -o $OutputVVP `
    -f $FilelistPath `
    -I $IncludePath1 `
    -I $IncludePath2 `
    -Wall

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Compilation successful" -ForegroundColor Green
} else {
    Write-Host "✗ Compilation failed" -ForegroundColor Red
    exit 1
}

# Run simulation
Write-Host ""
Write-Host "[3/4] Running simulation..." -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Blue

& vvp $OutputVVP

if ($LASTEXITCODE -eq 0) {
    Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Blue
    Write-Host "✓ Simulation completed" -ForegroundColor Green
} else {
    Write-Host "✗ Simulation failed" -ForegroundColor Red
    exit 1
}

# Check if VCD file was generated
$VCDFile = Join-Path $SimDir "bfs_system_complete.vcd"
if (Test-Path $VCDFile) {
    Write-Host "✓ VCD waveform file generated: bfs_system_complete.vcd" -ForegroundColor Green
    Write-Host ""
    Write-Host "[4/4] Launching GTKWave..." -ForegroundColor Yellow
    
    # Check if GTKWave is available
    $GTKWavePath = Get-Command gtkwave -ErrorAction SilentlyContinue
    if ($GTKWavePath) {
        $GTKWSaveFile = Join-Path $SimDir "bfs_system_complete.gtkw"
        
        # Launch GTKWave
        Start-Process gtkwave -ArgumentList $VCDFile, $GTKWSaveFile -NoNewWindow -PassThru | Out-Null
        Write-Host "✓ GTKWave launched" -ForegroundColor Green
    } else {
        Write-Host "⚠ GTKWave not found in PATH" -ForegroundColor Yellow
        Write-Host "  Install GTKWave to view waveforms:" -ForegroundColor Yellow
        Write-Host "  Download from: http://gtkwave.sourceforge.net/" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  You can manually open the VCD file later:" -ForegroundColor Cyan
        Write-Host "  gtkwave $VCDFile" -ForegroundColor White
    }
} else {
    Write-Host "✗ VCD file not generated" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "╔═════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  Simulation Complete!                                       ║" -ForegroundColor Blue
Write-Host "║  - Waveform: sim\iverilog\bfs_system_complete.vcd           ║" -ForegroundColor Blue
Write-Host "║  - Open manually: gtkwave bfs_system_complete.vcd           ║" -ForegroundColor Blue
Write-Host "╚═════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
