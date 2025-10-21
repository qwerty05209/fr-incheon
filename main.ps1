$targetPath = 'C:\Windows\SysWOW64'
$bootScript = 'C:\ProgramData\delete_jness_onboot.ps1'
$taskName = 'Delete_JNESS_OnBoot'

$results = Get-ChildItem -Path $targetPath -Filter *.exe -Recurse -Force -ErrorAction SilentlyContinue |
  ForEach-Object {
    try {
      $full = $_.FullName
      $sig = Get-AuthenticodeSignature -FilePath $full -ErrorAction SilentlyContinue
      $cert = $sig.SignerCertificate
      $matches = $false
      if ($cert) {
        foreach ($field in @($cert.Subject, $cert.Issuer, $cert.FriendlyName, $cert.GetName())) {
          if ($field -and ($field -imatch 'JNESS')) { $matches = $true; break }
        }
      }
      if ($matches) { $_.FullName }
    } catch { }
  }

if (-not $results) { exit }

@"
\$files = @(
$( $results | ForEach-Object { "`"$_`"" } | Out-String )
)

foreach (\$f in \$files) {
  try {
    if (Test-Path \$f) {
      Remove-Item -Path \$f -Force -ErrorAction SilentlyContinue
    }
  } catch {}
}
"@ | Set-Content -Path $bootScript -Encoding UTF8 -Force

try { schtasks /delete /tn $taskName /f | Out-Null } catch {}

$cmd = "powershell.exe -ExecutionPolicy Bypass -NoProfile -File `"`"$bootScript`"`""
Start-Process schtasks -ArgumentList "/create /tn `"$taskName`" /sc onstart /ru SYSTEM /rl HIGHEST /tr `"$cmd`"" -WindowStyle Hidden -Wait
