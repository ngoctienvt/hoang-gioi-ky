param([Parameter(Mandatory=$true)][string]$SourceDirectory)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceTarget = Join-Path $projectRoot 'assets/ui/art-source'
$runtimeTarget = Join-Path $projectRoot 'assets/ui/illustrations'
New-Item -ItemType Directory -Path $sourceTarget,$runtimeTarget -Force | Out-Null
Set-Content -LiteralPath (Join-Path $sourceTarget '.gdignore') -Value ''
$definitions = @(
    @{ name='menu-forest'; pattern='exec-2273036d*.png'; icon=$false },
    @{ name='ability-beast'; pattern='exec-6d077263-0ebb-4ca0-95a5-66d9cf37e996.png'; icon=$true },
    @{ name='ability-sense'; pattern='exec-3155efad-a027-48a6-8aef-b03ce314c70c.png'; icon=$true }
)
$records = @()
foreach ($entry in $definitions) {
    $matches = @(Get-ChildItem -LiteralPath $SourceDirectory -Filter $entry.pattern)
    if ($matches.Count -ne 1) { throw "Expected one source for $($entry.name), found $($matches.Count)" }
    $original = Join-Path $sourceTarget ($entry.name + '.png')
    Copy-Item -LiteralPath $matches[0].FullName -Destination $original
    $image = [System.Drawing.Bitmap]::new($original)
    $destination = Join-Path $runtimeTarget ($entry.name + '.png')
    try {
        if ($entry.icon) {
            $bitmap = [System.Drawing.Bitmap]::new(192,192,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $ratio = [Math]::Min(192.0/$image.Width,192.0/$image.Height)
                $width = [int][Math]::Round($image.Width*$ratio)
                $height = [int][Math]::Round($image.Height*$ratio)
                $graphics.DrawImage($image,[int]((192-$width)/2),[int]((192-$height)/2),$width,$height)
                $bitmap.Save($destination,[System.Drawing.Imaging.ImageFormat]::Png)
            } finally { $graphics.Dispose(); $bitmap.Dispose() }
        } else { Copy-Item -LiteralPath $original -Destination $destination }
    } finally { $image.Dispose() }
    $runtime = [System.Drawing.Bitmap]::new($destination)
    try {
        $transparent = 0
        $visible = 0
        for ($y=0; $y -lt $runtime.Height; $y++) {
            for ($x=0; $x -lt $runtime.Width; $x++) {
                $alpha = $runtime.GetPixel($x,$y).A
                if ($alpha -eq 0) { $transparent++ }
                if ($alpha -gt 0) { $visible++ }
            }
        }
        if ($entry.icon -and ($transparent -eq 0 -or $visible -eq 0)) { throw "Icon needs both visible pixels and genuine transparent pixels: $($entry.name)" }
        if ($entry.icon -and $transparent -lt (192*192*0.15)) { throw "Icon has too little transparent space: $($entry.name)" }
        $records += @{
            id=$entry.name; file=('assets/ui/illustrations/'+$entry.name+'.png');
            source=('assets/ui/art-source/'+$entry.name+'.png'); source_sha256=(Get-FileHash -LiteralPath $original -Algorithm SHA256).Hash;
            width=$runtime.Width; height=$runtime.Height; fully_transparent_pixels=$transparent;
            technical_checks_passed=$true; visual_approval='source inspected; in-game pending'
        }
        Write-Output "[UIArt] $($entry.name): $($runtime.Width)x$($runtime.Height), $transparent transparent pixels"
    } finally { $runtime.Dispose() }
}
@{ source_kind='AI-generated'; tool='built-in image_gen'; date='2026-11-23'; note='Original generated game UI artwork, no third-party source assets. Preserve AI disclosure when shipping. Source PNG files kept outside Godot import using .gdignore.'; assets=$records } |
    ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runtimeTarget 'art-manifest.json') -Encoding utf8
# A local, deterministic contact sheet makes native-scale readability inspectable without a browser.
$sheet = [System.Drawing.Bitmap]::new(640,248)
$canvas = [System.Drawing.Graphics]::FromImage($sheet)
try {
    $canvas.Clear([System.Drawing.ColorTranslator]::FromHtml('#202a25'))
    for ($i=0; $i -lt 2; $i++) {
        $name = @('ability-beast','ability-sense')[$i]
        $icon = [System.Drawing.Bitmap]::new((Join-Path $runtimeTarget ($name+'.png')))
        try {
            $canvas.DrawImage($icon,($i*320+12),8,192,192)
            $canvas.DrawImage($icon,($i*320+222),24,48,48)
            $canvas.DrawImage($icon,($i*320+230),96,32,32)
            $canvas.DrawString($name,[System.Drawing.SystemFonts]::DefaultFont,[System.Drawing.Brushes]::Ivory,($i*320+24),216)
        } finally { $icon.Dispose() }
    }
    $sheet.Save((Join-Path $projectRoot 'plans/reports/ui-art-preview-261123-1601.png'),[System.Drawing.Imaging.ImageFormat]::Png)
} finally { $canvas.Dispose(); $sheet.Dispose() }
