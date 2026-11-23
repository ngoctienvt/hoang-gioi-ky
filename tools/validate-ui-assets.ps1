# Static asset checks only; does not start Godot, run gameplay tests, or compile code.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $projectRoot 'assets/ui/asset-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$seen = @{}
foreach ($entry in $manifest.assets) {
    if ($seen.ContainsKey($entry.id)) { throw "Duplicate icon id: $($entry.id)" }
    $seen[$entry.id] = $true
    $assetPath = Join-Path $projectRoot $entry.file
    [xml]$svg = Get-Content -LiteralPath $assetPath -Raw
    if ($svg.svg.width -ne '96' -or $svg.svg.height -ne '96' -or $svg.svg.viewBox -ne '0 0 96 96') {
        throw "Wrong SVG dimensions: $($entry.file)"
    }
    if ($svg.SelectNodes("//*[local-name()='image' or local-name()='script' or local-name()='foreignObject']").Count -gt 0) {
        throw "External or active content in icon: $($entry.file)"
    }
    if ($svg.SelectNodes("//*[local-name()='rect']").Count -gt 0) { throw "Unexpected background rectangle: $($entry.file)" }
    if ($svg.OuterXml -match 'href=|url\(|\{c\}') { throw "Unresolved or external reference: $($entry.file)" }
    $entry.technical_checks_passed = $true
}
$itemCount = 0
foreach ($itemFile in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'data/items') -Filter '*.tres') {
    $data = Get-Content -LiteralPath $itemFile.FullName -Raw
    if ($data -notmatch 'icon = ExtResource\("ui_icon"\)') { throw "Missing item icon: $($itemFile.Name)" }
    $resourceIds = [regex]::Matches($data, '^\[ext_resource[^\r\n]* id="([^"]+)"\]', 'Multiline')
    if (($resourceIds | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique).Count -ne $resourceIds.Count) {
        throw "Duplicate resource id: $($itemFile.Name)"
    }
    foreach ($match in [regex]::Matches($data, 'path="res://([^"]+)"')) {
        if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $match.Groups[1].Value))) { throw "Broken resource: $($match.Value)" }
    }
    $itemCount++
}
$manifest | Add-Member -NotePropertyName technical_check_scope -NotePropertyValue 'SVG XML, 96x96 canvas, no background rectangles or embedded/external content; all ItemDef icon links exist. Raster alpha and in-engine visual acceptance pending.' -Force
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Output "[UIAssets] PASS: $($manifest.assets.Count) SVG files; $itemCount ItemDef icon bindings. Visual acceptance pending."
