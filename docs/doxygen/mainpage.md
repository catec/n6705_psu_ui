# N6705 Power Console Documentation

Author: Mouhsine Kassimi Farhaoui  
Mail: mouhsine98@gmail.com

## Overview

N6705 Power Console is a production-oriented desktop application for remote control, telemetry, and consumption logging of Keysight N6705 analyzers over SCPI/TCP.

## App Icon

<p align="center">
  <img src="../../assets/icons/n6705_app_icon.svg" alt="N6705 Power Console app icon" width="220" />
</p>

## Technology Stack

- Python 3.10+
- PySide6 (Qt/QML)
- MVVM + Ports/Adapters architecture
- CSV historical analytics and PNG export

## Documentation Map

- Architecture reference: `docs/doxygen/architecture.md`
- End-to-end tutorial: `docs/doxygen/tutorial.md`
- UML and system diagrams: `docs/doxygen/diagrams.md`
- Project onboarding: `README.md`

## Windows Packaging

The project provides a production-style Windows packaging pipeline:

- `PyInstaller` for standalone app bundle
- `Inno Setup` for final installer EXE

Key files:

- `packaging/windows/build_installer.ps1`
- `packaging/windows/installer.iss`
- `packaging/windows/make_icon.py`
