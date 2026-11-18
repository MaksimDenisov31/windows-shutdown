$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assetsPath = Join-Path $PSScriptRoot 'assets'
$outputPath = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Path $assetsPath, $outputPath -Force | Out-Null

# Draw a standard power symbol as a multiresolution Windows icon.
$iconPath = Join-Path $assetsPath 'shutdown.ico'
$frames = @()
foreach ($size in @(16, 24, 32, 48, 64, 128, 256)) {
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $scale = $size / 256.0
    $graphics.ScaleTransform($scale, $scale)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 42, 48))
    $graphics.FillEllipse($brush, 4, 4, 248, 248)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 19)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawArc($pen, 65, 65, 126, 126, -48, 276)
    $graphics.DrawLine($pen, 128, 53, 128, 126)
    $stream = New-Object System.IO.MemoryStream
    $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $frames += ,@{ Size = $size; Bytes = $stream.ToArray() }
    $stream.Dispose()
    $pen.Dispose()
    $brush.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}
$file = [System.IO.File]::Create($iconPath)
$writer = New-Object System.IO.BinaryWriter($file)
try {
    $writer.Write([uint16]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]$frames.Count)
    $offset = 6 + 16 * $frames.Count
    foreach ($frame in $frames) {
        $dimension = if ($frame.Size -eq 256) { 0 } else { $frame.Size }
        $writer.Write([byte]$dimension)
        $writer.Write([byte]$dimension)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]32)
        $writer.Write([uint32]$frame.Bytes.Length)
        $writer.Write([uint32]$offset)
        $offset += $frame.Bytes.Length
    }
    foreach ($frame in $frames) { $writer.Write([byte[]]$frame.Bytes) }
} finally {
    $writer.Dispose()
}

$compilerPath = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$executablePath = Join-Path $outputPath 'Выключение Windows.exe'
& $compilerPath /nologo /target:winexe /optimize+ /platform:anycpu "/win32icon:$iconPath" /reference:System.Windows.Forms.dll "/out:$executablePath" (Join-Path $PSScriptRoot 'Program.cs')
if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $LASTEXITCODE" }
Write-Output "Built: $executablePath"
