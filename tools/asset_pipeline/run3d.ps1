# Buoc 2-5: prep -> (WSL) Omni + Paint -> rig thu 4 chan -> hgk_fit -> anh xem truoc. Chay lai duoc (bo mon da xong).
param([string[]]$keys, [switch]$FitOnly)
$R = 'C:\Users\Admin\workspace\animation2d'; $G = "$R\hoang-gioi-ky"; $H = "$G\tools\asset_pipeline"; $O = 'D:\hgk_models'
$py = 'C:\Users\Admin\AppData\Local\Programs\Python\Python311\python.exe'; $bl = 'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe'
function St($m) { $l = "$(Get-Date -Format 'HH:mm:ss') $m"; Add-Content "$O\status.txt" $l; $l }
$env:HGK_KEEP = "1"  # 23-11: giu mesh goc Omni, khong giam tam giac
New-Item -ItemType Directory -Force "$O\rig", "$O\low", "$G\art-source\previews\models" | Out-Null
if (-not $FitOnly) {
& $py -X utf8 "$H\prep.py" @keys
St "BAT DAU 3D"
try { Invoke-RestMethod -Method Post http://127.0.0.1:8188/free -Body '{"unload_models":true,"free_memory":true}' -ContentType 'application/json' | Out-Null } catch {}
$n = (Get-Content "$O\m\names.json" -Raw | ConvertFrom-Json).Count
for ($i = 0; $i -lt 3; $i++) {
  wsl -d Ubuntu-24.04 -- bash -lc "sed -i 's/\r$//' /mnt/c/Users/Admin/workspace/animation2d/hoang-gioi-ky/tools/asset_pipeline/run_wsl.sh; bash /mnt/c/Users/Admin/workspace/animation2d/hoang-gioi-ky/tools/asset_pipeline/run_wsl.sh >> /mnt/d/hgk_models/wsl.log 2>&1"
  $nm = Get-Content "$O\m\names.json" -Raw | ConvertFrom-Json; $done = @($nm | Where-Object { Test-Path "$O\m\$_\textured.glb" }).Count; St "WSL luot $i : $done/$n textured"
  if ($done -ge $n) { break }
}
}
$items = Get-Content "$H\items.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$outs = @()
foreach ($it in $items) {
  if ($keys -and -not ($keys -contains $it.key)) { continue }
  $src = "$O\m\$($it.key)\textured.glb"; if (-not (Test-Path $src)) { St "THIEU $($it.key)"; continue }
  $dst = "$G\assets\models\$($it.folder)\$($it.key)\$($it.file).glb"; New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
  if ($it.rig) {
    $rg = "$O\rig\$($it.key)_full.glb"
    if (-not (Test-Path $rg)) {
      $rt = switch ($it.rig) { 'bird' { @("$R\tools\studio\bird_rig.py", '--model', $src, '--out', $rg, '--faces', '0', '--tex', '8192') } { $_ -in 'hop', 'float' } { @("$R\tools\studio\rigid_rig.py", '--model', $src, '--out', $rg, '--style', $it.rig, '--faces', '10000000', '--tex', '8192') } default { @("$R\tools\studio\creature_rig.py", '--kind', $it.rig, '--model', $src, '--out', $rg, '--faces', '0', '--tex', '8192') } }
      $p = Start-Process -FilePath $bl -ArgumentList (@('-b', '-P') + $rt[0] + @('--') + $rt[1..($rt.Count - 1)]) -RedirectStandardOutput "$O\rig\$($it.key).log" -RedirectStandardError "$O\rig\$($it.key).err" -PassThru -WindowStyle Hidden
      if (-not $p.WaitForExit(600000)) { $p.Kill() }
    }
    if (Test-Path $rg) { $src = $rg } else { St "RIG_FAIL $($it.key) (xuat ban tinh)" }
  }
  $dims = ($it.dims -join ','); $var = if ($it.variants) { $vf = "$O\low\$($it.key)_variants.json"; [IO.File]::WriteAllText($vf, ($it.variants | ConvertTo-Json -Compress)); $vf } else { $null }
  $env:HGK_NOFLOOR = if ($it.rig -eq 'bird') { "1" } else { $null }
  $args2 = @('-b', '-P', "$H\hgk_fit.py", '--', $src, $dst, $dims, "$($it.tris)", "$($it.tex)"); if ($var) { $args2 += $var }
  & $bl @args2 2>&1 | Select-String 'FIT_DONE|VARIANT_DONE|Error|Traceback' | ForEach-Object { $_.Line }
  if (Test-Path $dst) { $outs += $dst }
  if ($it.variants) { foreach ($v in $it.variants.PSObject.Properties.Name) { $outs += "$G\assets\models\$($it.folder)\$v\$v.glb" } }
}
$env:HGK_LOW = $null
St "FIT XONG $($outs.Count) file"
for ($i = 0; $i -lt $outs.Count; $i += 12) {
  $chunk = $outs[$i..([Math]::Min($i + 11, $outs.Count - 1))]
  & $bl -b -P "$H\preview.py" -- "$G\art-source\previews\models" @chunk 2>&1 | Select-String 'PREVIEW|Error' | ForEach-Object { $_.Line.Substring(0, [Math]::Min(160, $_.Line.Length)) }
}
& $py -X utf8 "$H\sheet.py"
St "XONG HET"
