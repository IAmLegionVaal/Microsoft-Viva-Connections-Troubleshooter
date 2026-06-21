# Microsoft Viva Connections Troubleshooter

Windows PowerShell 5.1 diagnostics and guarded repair tooling created by **Dewald Pretorius**.

## Files

- `Troubleshooter.ps1` collects the original Viva Connections endpoint and configuration evidence.
- `Repair.ps1` adds read-only diagnosis plus reversible local client repair actions.

## Repair actions

- `Diagnose` — saves process, cache and endpoint state without changing the computer.
- `ResetCache` — stops Teams/Edge processes, moves relevant cache folders to timestamped `.backup-*` locations and recreates clean folders.
- `FlushDns` — clears the Windows DNS client cache.

```powershell
.\Troubleshooter.ps1
.\Repair.ps1 -Action Diagnose
.\Repair.ps1 -Action ResetCache -DryRun
.\Repair.ps1 -Action ResetCache -Yes
```

Mutating actions require confirmation unless `-Yes` is supplied. Every run writes a timestamped log and pre-repair JSON snapshot. Exit codes are `0` success, `2` invalid input, `3` missing prerequisite, `4` cancelled, `5` action failure and `6` verification failure.

The workflow has been source-reviewed for Windows PowerShell 5.1 safety controls but has not been runtime-tested against every tenant, Teams build or Windows configuration.
