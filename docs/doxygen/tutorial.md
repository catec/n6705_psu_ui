# End-to-End Usage Tutorial

Author: Mouhsine Kassimi Farhaoui  
Mail: mouhsine98@gmail.com

## 1. Environment Setup

```bash
python -m venv .venv
# Linux/macOS
source .venv/bin/activate
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## 2. Run the Application

```bash
python app.py
```

## 3. Connect to the Instrument

1. Open Connection Properties.
2. Set Host/IP, Port (typically 5025), Timeout.
3. Click Connect.
4. Confirm IDN and link state in the top status area.

## 4. Operate Channels

1. Select active channel (CH1..CH4).
2. Set voltage/current setpoints.
3. Apply values and verify readback.
4. Toggle channel output ON/OFF.

## 5. Monitor Live Data

- Meter View: live values and setpoints per channel
- Scope View: V/I/P traces over time + Ah/Wh trends
- Data Logger: event stream and channel cards

## 6. Capture CSV Logs

1. Configure CSV path manually or with Browse.
2. Start Log.
3. Run your measurement scenario.
4. Stop Log and inspect generated CSV.

## 7. Analyze Historical Logs

1. Open Log Plot.
2. Load one or more CSV files.
3. Filter by file/channel.
4. Inspect voltage/current/power/charge/energy charts.
5. Export the panel to PNG.

## 8. Troubleshooting

- Connection timeout: validate IP route/firewall/port.
- Empty telemetry: ensure monitoring is running and channels are selected.
- Logging errors: verify output path permissions.
- Plugin load on Windows: ensure PySide6 DLL directory is resolvable.

## 9. Build Windows Installer

From repository root:

```powershell
.\packaging\windows\build_installer.cmd -AppVersion 1.0.0
```

Alternative direct PowerShell call:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\packaging\windows\build_installer.ps1 -AppVersion 1.0.0
```

Artifacts:

- `dist/windows/app/N6705PowerConsole/` (portable app bundle)
- `dist/windows/installer/n6705-power-console-1.0.0-setup.exe` (installer)

Notes:

- Build machine requires Inno Setup 6 (`iscc.exe` in `PATH`)
- End users only need the generated setup EXE
