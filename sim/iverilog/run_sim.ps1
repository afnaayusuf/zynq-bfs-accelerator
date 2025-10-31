# Simple BFS Accelerator Simulation Script
# ==========================================

Write-Host "BFS Accelerator - Icarus Verilog Simulation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to simulation directory
$SimDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $SimDir

# Check if graph data exists
$GraphFile = "..\..\test_data\complex_graph_memory.mem"
if (-not (Test-Path $GraphFile)) {
    Write-Host "ERROR: Graph memory file not found!" -ForegroundColor Red
    Write-Host "Expected: $GraphFile" -ForegroundColor Red
    exit 1
}

Write-Host "[PASS] Graph data found" -ForegroundColor Green

# Check if Icarus Verilog is installed
try {
    $null = Get-Command iverilog -ErrorAction Stop
    Write-Host "[PASS] Icarus Verilog found" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Icarus Verilog not found!" -ForegroundColor Red
    Write-Host "Install with: winget install IcarusVerilog" -ForegroundColor Yellow
    exit 1
}

# Compile
Write-Host ""
Write-Host "Compiling RTL..." -ForegroundColor Yellow

$CompileCmd = "iverilog -g2012 -o bfs_system_sim.vvp -f filelist_iverilog.f -I ..\..\rtl\packages -I ..\..\rtl -Wall 2>&1"
$CompileOutput = Invoke-Expression $CompileCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: Compilation errors" -ForegroundColor Red
    Write-Host $CompileOutput
    exit 1
} else {
    Write-Host "[PASS] Compilation successful" -ForegroundColor Green
    # Show warnings if any
    $Warnings = $CompileOutput | Select-String "warning"
    if ($Warnings) {
        Write-Host "Warnings: $($Warnings.Count)" -ForegroundColor Yellow
    }
}

# Run simulation
Write-Host ""
Write-Host "Running simulation..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Blue

vvp bfs_system_sim.vvp

if ($LASTEXITCODE -eq 0) {
    Write-Host "----------------------------------------" -ForegroundColor Blue
    Write-Host "[PASS] Simulation completed" -ForegroundColor Green
} else {
    Write-Host "FAILED: Simulation error" -ForegroundColor Red
    exit 1
}

# Check for VCD file
if (Test-Path "bfs_system_complete.vcd") {
    Write-Host "[PASS] VCD waveform generated" -ForegroundColor Green
    
    # Try to launch GTKWave
    try {
        $null = Get-Command gtkwave -ErrorAction Stop
        Write-Host ""
        Write-Host "Launching GTKWave..." -ForegroundColor Yellow
        Start-Process gtkwave -ArgumentList "bfs_system_complete.vcd","bfs_system_complete.gtkw"
        Write-Host "[PASS] GTKWave launched" -ForegroundColor Green
    } catch {
        Write-Host "GTKWave not found (optional)" -ForegroundColor Yellow
        Write-Host "Install from: http://gtkwave.sourceforge.net/" -ForegroundColor Cyan
    }
} else {
    Write-Host "WARNING: VCD file not generated" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Simulation Complete!" -ForegroundColor Cyan
Write-Host "Waveform: bfs_system_complete.vcd" -ForegroundColor Cyan
Write-Host ""
