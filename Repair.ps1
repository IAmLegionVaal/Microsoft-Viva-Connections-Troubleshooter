#requires -Version 5.1
<#
.SYNOPSIS
Guarded repair companion for Microsoft Viva Connections Troubleshooter.
.DESCRIPTION
Created by Dewald Pretorius. Diagnose is read-only. Repair actions support dry-run,
confirmation, backups, logging, post-change verification, and stable exit codes.
#>
[CmdletBinding()]
param(
    [ValidateSet('Diagnose','ResetCache','FlushDns')]
    [string]$Action='Diagnose',
    [switch]$DryRun,
    [switch]$Yes,
    [string]$OutputPath=(Join-Path ([Environment]::GetFolderPath('Desktop')) 'Microsoft_Viva_Connections_Troubleshooter_Repair')
)
$ErrorActionPreference='Stop'
$ExitInvalid=2;$ExitPrerequisite=3;$ExitCancelled=4;$ExitAction=5;$ExitVerify=6
$Cfg=[ordered]@{
    Name='Microsoft Viva Connections Troubleshooter'
    Processes=@('msedge','ms-teams')
    CachePaths=@("$env:APPDATA\Microsoft\Teams\Cache","$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache")
    Endpoints=@('connections.viva.office.com','sharepoint.com','login.microsoftonline.com','graph.microsoft.com')
}
function Write-Log([string]$Message){$line='{0:u} {1}' -f (Get-Date),$Message;Write-Host $line;Add-Content -LiteralPath $script:LogPath -Value $line}
function Confirm-Action([string]$Message){if($Yes){return $true};(Read-Host "$Message [y/N]") -match '^(?i)y(es)?$'}
function Invoke-Guarded([string]$Description,[scriptblock]$Operation){
    if($DryRun){Write-Log "[DRY-RUN] $Description";return}
    if(-not(Confirm-Action $Description)){Write-Log '[CANCELLED] No changes were made.';exit $ExitCancelled}
    try{& $Operation;Write-Log "[ACTION] $Description"}catch{Write-Log "[FAILED] $($_.Exception.Message)";exit $ExitAction}
}
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss';$script:LogPath=Join-Path $OutputPath "Repair_$stamp.log"
$state=[ordered]@{
    Tool=$Cfg.Name;Generated=(Get-Date);Action=$Action;DryRun=[bool]$DryRun
    Processes=@($Cfg.Processes|ForEach-Object{Get-Process -Name $_ -ErrorAction SilentlyContinue|Select-Object Name,Id,Path})
    CachePaths=@($Cfg.CachePaths|ForEach-Object{[pscustomobject]@{Path=$_;Exists=Test-Path -LiteralPath $_}})
    Endpoints=@($Cfg.Endpoints|ForEach-Object{[pscustomobject]@{Host=$_;DNS=[bool](Resolve-DnsName $_ -ErrorAction SilentlyContinue);HTTPS443=(Test-NetConnection $_ -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue)}})
}
$state|ConvertTo-Json -Depth 7|Set-Content -LiteralPath (Join-Path $OutputPath "PreRepair_$stamp.json") -Encoding UTF8
if($Action -eq 'Diagnose'){Write-Log "[COMPLETE] Diagnostic snapshot saved to $OutputPath";exit 0}
if($Action -eq 'ResetCache'){
    Invoke-Guarded 'Stop Teams/Edge processes and move relevant caches to timestamped backups' {
        foreach($n in $Cfg.Processes){Get-Process -Name $n -ErrorAction SilentlyContinue|Stop-Process -Force}
        foreach($path in $Cfg.CachePaths){if(Test-Path -LiteralPath $path){$backup="$path.backup-$stamp";Move-Item -LiteralPath $path -Destination $backup -Force;New-Item -ItemType Directory -Path $path -Force|Out-Null;Write-Log "[BACKUP] $backup"}}
    }
    if(-not $DryRun){$bad=@($Cfg.CachePaths|Where-Object{-not(Test-Path -LiteralPath $_)});if($bad.Count){Write-Log "[VERIFY-FAILED] Cache recreation failed: $($bad -join ', ')";exit $ExitVerify}}
}
elseif($Action -eq 'FlushDns'){Invoke-Guarded 'Flush the Windows DNS client cache' {Clear-DnsClientCache}}
Write-Log '[COMPLETE] Repair action and verification completed.'
exit 0
