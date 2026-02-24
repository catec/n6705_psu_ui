"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file n6705_ui/qml_main.py
@brief Qt/QML bootstrap and application startup wiring.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""


from __future__ import annotations

import os
import sys
from pathlib import Path

import PySide6
from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from n6705_ui.presentation.viewmodels.dashboard_vm import DashboardViewModel


def _runtime_root() -> Path:
    """Return resource root for source and frozen executions."""
    if getattr(sys, "frozen", False):
        return Path(getattr(sys, "_MEIPASS", Path(sys.executable).resolve().parent))
    return Path(__file__).resolve().parent.parent


def _qml_main_file(root: Path) -> Path:
    """Resolve Main.qml path from runtime root."""
    frozen_candidate = root / "n6705_ui" / "presentation" / "qml" / "Main.qml"
    if frozen_candidate.exists():
        return frozen_candidate
    return Path(__file__).resolve().parent / "presentation" / "qml" / "Main.qml"


def main() -> int:
    runtime_root = _runtime_root()

    # Ensure Windows can resolve Qt runtime dependencies for QML plugins.
    if sys.platform == "win32":
        if getattr(sys, "frozen", False):
            dll_root = runtime_root / "PySide6"
        else:
            dll_root = Path(PySide6.__file__).resolve().parent
        if dll_root.exists():
            os.add_dll_directory(str(dll_root))

    QQuickStyle.setStyle("Material")
    app = QGuiApplication(sys.argv)
    icon_file = runtime_root / "assets" / "icons" / "n6705_app_icon.svg"
    if icon_file.exists():
        app.setWindowIcon(QIcon(str(icon_file)))
    engine = QQmlApplicationEngine()

    dashboard = DashboardViewModel()
    app.aboutToQuit.connect(dashboard.saveSessionConfig)
    engine.rootContext().setContextProperty("dashboard", dashboard)

    qml_file = _qml_main_file(runtime_root)
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        return 1
    return app.exec()





