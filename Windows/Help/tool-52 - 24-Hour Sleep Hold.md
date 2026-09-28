# 24-Hour Sleep Hold

## What this tool does

**24-Hour Sleep Hold** temporarily prevents a Windows computer from entering sleep and then automatically restores the previous power settings.

The Field Kit version is generic and portable. It is not tied to a company, file server, VPN client, mapped drive, Lansweeper deployment, or fixed reporting share.

## When to use it

Use this tool when a Windows computer must remain awake for a long maintenance, data-transfer, recovery, imaging, update, or diagnostic session.

Examples:

- copying a large amount of data,
- running a long repair or scan,
- performing overnight maintenance,
- preventing an unattended diagnostic from being interrupted by sleep.

## What it changes

The tool temporarily changes the active Windows power scheme:

- sleep timeout on AC power -> disabled,
- sleep timeout on battery -> disabled,
- hibernate timeout -> disabled when supported,
- disk idle timeout -> disabled when supported.

It intentionally **does not change the display/screen timeout**.

By default it also:

- attempts to abort an already-pending Windows shutdown timer,
- finds enabled scheduled tasks whose actions clearly invoke shutdown, restart, or logoff,
- disables only those matching tasks,
- records exactly which tasks it changed,
- creates a local SYSTEM rollback task,
- automatically restores the saved state after the requested hold period.

## Automatic rollback

Default duration:

**24 hours**

The script stores the previous state under:

`%ProgramData%\T3DFK\SleepHold`

It creates a local rollback task named:

`T3DFK Temporary Sleep Hold Rollback`

When the hold expires, the rollback restores:

- previous sleep timeout,
- previous hibernate timeout when supported,
- previous disk timeout,
- only the scheduled tasks that this Field Kit run disabled.

## What it does NOT do

It does not:

- change the monitor/display timeout,
- require a network share,
- require Internet access,
- require a domain,
- require Cisco VPN,
- permanently disable scheduled tasks,
- delete scheduled tasks,
- reboot or shut down the computer.

## Requirements

- Windows PowerShell 5.1
- administrator rights

The Field Kit automatically detects the administrator requirement.

## Default run

Click:

**System Management -> 24-Hour Sleep Hold**

The default app run is equivalent to:

```powershell
.\Disable-SleepHold.ps1
```

This applies a 24-hour hold.

## Optional command-line parameters

### Change duration

```powershell
.\Disable-SleepHold.ps1 -DurationHours 8
```

Supported range:

- minimum: 0.25 hour
- maximum: 168 hours

### Manually roll back early

```powershell
.\Disable-SleepHold.ps1 -Rollback
```

### Do not disable scheduled shutdown/restart/logoff tasks

```powershell
.\Disable-SleepHold.ps1 -SkipScheduledShutdownTaskDisable
```

### Do not attempt to abort an existing shutdown timer

```powershell
.\Disable-SleepHold.ps1 -SkipPendingShutdownAbort
```

## Reports

When launched from the Field Kit, the report is written under the Field Kit diagnostic report directory.

The report records:

- computer name,
- hold duration,
- previous settings,
- pending-shutdown result,
- scheduled tasks disabled,
- rollback time,
- local state location,
- warnings or failures.

## Risk level

**High Risk / System Change**

The changes are intentionally temporary and state-backed, but this tool modifies power behavior and can disable matching scheduled shutdown/restart/logoff tasks during the hold.

Do not use it without understanding why the computer normally has those tasks.

## How to verify success

After running:

1. Confirm the Run Center reports `[PASS] Sleep hold applied`.
2. Confirm the rollback time is correct.
3. Confirm the computer no longer enters sleep during the maintenance window.
4. Check Task Scheduler for `T3DFK Temporary Sleep Hold Rollback`.
5. After expiration or manual rollback, verify the original power behavior returns.

## Preserved original

The original supplied site-specific script is still retained unchanged at:

`Windows\Scripts\Maintenance\Disable-Sleep24.ps1`

The app intentionally runs the portable Field Kit adaptation instead:

`Windows\Scripts\FieldKit\Disable-SleepHold.ps1`
