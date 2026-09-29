param(
    [string]$SourcePath = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$workspace = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = Join-Path $workspace "assets\app_logo\app_icon_foreground_source.png"
}
$source = [System.Drawing.Bitmap]::FromFile($SourcePath)
$res = Join-Path $workspace "android\app\src\main\res"

function Set-HighQuality([System.Drawing.Graphics]$graphics) {
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
}

function Draw-Foreground(
    [System.Drawing.Graphics]$graphics,
    [System.Drawing.Image]$image,
    [int]$size
) {
    $target = [int][Math]::Round($size * 0.78)
    $offset = [int][Math]::Round(($size - $target) / 2)
    $graphics.DrawImage($image, $offset, $offset, $target, $target)
}

function New-RoundedPath([int]$size, [int]$radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2
    $path.AddArc(0, 0, $diameter, $diameter, 180, 90)
    $path.AddArc($size - $diameter, 0, $diameter, $diameter, 270, 90)
    $path.AddArc($size - $diameter, $size - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc(0, $size - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Save-LegacyIcon([int]$size, [string]$path, [bool]$round) {
    $bitmap = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    Set-HighQuality $graphics
    $graphics.Clear([System.Drawing.Color]::Transparent)
    if ($round) {
        $clip = New-Object System.Drawing.Drawing2D.GraphicsPath
        $clip.AddEllipse(0, 0, $size, $size)
    } else {
        $clip = New-RoundedPath $size ([int][Math]::Round($size * 0.22))
    }
    $graphics.SetClip($clip)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
    $gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.ColorTranslator]::FromHtml("#2F7DD1"),
        [System.Drawing.ColorTranslator]::FromHtml("#071B43"),
        45.0
    )
    $graphics.FillRectangle($gradient, $rect)
    Draw-Foreground $graphics $source $size
    $directory = Split-Path -Parent $path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $gradient.Dispose()
    $clip.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

try {
    $adaptiveDirectory = Join-Path $res "drawable-nodpi"
    New-Item -ItemType Directory -Force -Path $adaptiveDirectory | Out-Null
    $foregroundPath = Join-Path $adaptiveDirectory "app_icon_foreground_art.png"
    $foreground = New-Object System.Drawing.Bitmap(432, 432, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($foreground)
    Set-HighQuality $graphics
    $graphics.Clear([System.Drawing.Color]::Transparent)
    Draw-Foreground $graphics $source 432
    $foreground.Save($foregroundPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()

    $monochrome = New-Object System.Drawing.Bitmap(432, 432, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt 432; $y++) {
        for ($x = 0; $x -lt 432; $x++) {
            $pixel = $foreground.GetPixel($x, $y)
            $isWhiteCar = $pixel.R -gt 165 -and $pixel.G -gt 165 -and $pixel.B -gt 165
            $isTurquoisePump = $pixel.G -gt 135 -and $pixel.B -gt 85 -and $pixel.G -gt ($pixel.R * 1.25)
            if ($pixel.A -gt 8 -and ($isWhiteCar -or $isTurquoisePump)) {
                $monochrome.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, 255, 255, 255))
            }
        }
    }
    $monochrome.Save(
        (Join-Path $adaptiveDirectory "app_icon_monochrome_art.png"),
        [System.Drawing.Imaging.ImageFormat]::Png
    )
    $monochrome.Dispose()
    $foreground.Dispose()

    $densities = @{
        "mipmap-mdpi" = 48
        "mipmap-hdpi" = 72
        "mipmap-xhdpi" = 96
        "mipmap-xxhdpi" = 144
        "mipmap-xxxhdpi" = 192
    }
    foreach ($entry in $densities.GetEnumerator()) {
        $directory = Join-Path $res $entry.Key
        Save-LegacyIcon $entry.Value (Join-Path $directory "ic_launcher.png") $false
        Save-LegacyIcon $entry.Value (Join-Path $directory "ic_launcher_round.png") $true
    }
} finally {
    $source.Dispose()
}
