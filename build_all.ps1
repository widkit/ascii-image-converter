$ErrorActionPreference = "Stop"

$AppName = "ascii-image-converter"
$Version = "v1.0.0"  # You can dynamically extract this from git if needed

$Targets = @(
    @{GOOS="linux";   GOARCH="amd64"},
    @{GOOS="linux";   GOARCH="arm64"},
    @{GOOS="linux";   GOARCH="arm";   GOARM="6"},
    @{GOOS="linux";   GOARCH="386"},
    @{GOOS="darwin";  GOARCH="amd64"},
    @{GOOS="darwin";  GOARCH="arm64"},
    @{GOOS="windows"; GOARCH="amd64"},
    @{GOOS="windows"; GOARCH="arm64"},
    @{GOOS="windows"; GOARCH="arm";   GOARM="6"},
    @{GOOS="windows"; GOARCH="386"}
)

function Compress-Folder($folderPath, $outputPath, $isZip) {
    if ($isZip) {
        Compress-Archive -Path "$folderPath\*" -DestinationPath $outputPath
    } else {
        tar -czf $outputPath -C (Split-Path $folderPath) (Split-Path $folderPath -Leaf)
    }
}

foreach ($target in $Targets) {
    $env:GOOS = $target.GOOS
    $env:GOARCH = $target.GOARCH
    if ($target.ContainsKey("GOARM")) {
        $env:GOARM = $target.GOARM
    } else {
        Remove-Item Env:GOARM -ErrorAction SilentlyContinue
    }

    $archSuffix = if ($env:GOARCH -eq "386" -or $env:GOARCH -eq "arm") { "32bit" } else { "64bit" }
    $outDir = "$AppName" + "_$($env:GOOS)_$($env:GOARCH)_$archSuffix"
    $ext = if ($env:GOOS -eq "windows") { ".exe" } else { "" }

    $outputPath = "dist\$outDir\$AppName$ext"
    New-Item -ItemType Directory -Path "dist\$outDir" -Force | Out-Null

    Write-Host "Building for $env:GOOS/$env:GOARCH GOARM=$env:GOARM..."
    & go build -o $outputPath .

    # Compress and clean up
    if ($env:GOOS -eq "windows") {
        Compress-Folder "dist\$outDir" "dist\$outDir.zip" $true
    } else {
        Compress-Folder "dist\$outDir" "dist\$outDir.tar.gz" $false
    }
    Remove-Item -Recurse -Force "dist\$outDir"
}

Write-Host "✅ All builds complete."
