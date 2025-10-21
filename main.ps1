$targetPath = 'C:\Windows\SysWOW64'
$bootScript = 'C:\ProgramData\delete_jness_onboot.ps1'
$taskName = 'Delete_JNESS_OnBoot'

$results = Get-ChildItem -Path $targetPath -Filter *.exe -Recurse -Force -ErrorAction SilentlyContinue |
  Where-Object {
    try {
      $sig = Get-AuthenticodeSignature -FilePath $_.FullName -ErrorAction SilentlyContinue
      $cert = $sig.SignerCertificate
      if ($cert) {
        $cert.Subject -match 'JNESS' -or
        $cert.Issuer -match 'JNESS' -or
        $cert.FriendlyName -match 'JNESS' -or
        $cert.GetName() -match 'JNESS'
      }
    } catch { $false }
  } |
  Select-Object -ExpandProperty FullName

if (-not $results) {
  exit
}

$filesList = $results | ForEach-Object { "  `"`$_`"," }
$joined = $filesList -join "`n"

$scriptContent = @"
`$files = @(
$joined
)

foreach (`$f in `$files) {
  try {
    if (Test-Path `$f) {
      Remove-Item -Path `$f -Force -ErrorAction SilentlyContinue
    }
  } catch {}
}
"@

$scriptContent | Set-Content -Path $bootScript -Encoding UTF8 -Force
try { schtasks /delete /tn $taskName /f | Out-Null } catch {}

$cmd = "powershell.exe -ExecutionPolicy Bypass -NoProfile -File `"$bootScript`""
schtasks /create /tn $taskName /sc onstart /ru SYSTEM /rl HIGHEST /tr $cmd /f
