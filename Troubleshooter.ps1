#requires -Version 5.1
<# Created by Dewald Pretorius #>
param([string]$OutputPath)
if(-not $OutputPath){$OutputPath="$([Environment]::GetFolderPath('Desktop'))\Viva_Connections_Reports"};New-Item $OutputPath -ItemType Directory -Force|Out-Null
$targets='connections.viva.office.com','sharepoint.com','login.microsoftonline.com','graph.microsoft.com';$net=foreach($t in $targets){[pscustomobject]@{Target=$t;DNS=[bool](Resolve-DnsName $t -ErrorAction SilentlyContinue);HTTPS443=(Test-NetConnection $t -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue)}}
@('MICROSOFT VIVA CONNECTIONS TROUBLESHOOTER','Created by Dewald Pretorius',"Generated: $(Get-Date)",($net|Format-Table -AutoSize|Out-String -Width 220),'Guidance: verify home-site configuration, dashboard permissions, card configuration, SharePoint access, Teams deployment, mobile experience, and audience targeting.')|Set-Content (Join-Path $OutputPath 'Report.txt') -Encoding UTF8