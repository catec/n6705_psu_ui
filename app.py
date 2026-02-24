"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file app.py
@brief Application entrypoint for the N6705 Power Console.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""


try:
    from n6705_ui.qml_main import main
except ModuleNotFoundError as exc:
    if exc.name == "PySide6":
        raise SystemExit(
            "PySide6 is not installed. Run: pip install -r requirements.txt"
        ) from exc
    raise


if __name__ == "__main__":
    raise SystemExit(main())





