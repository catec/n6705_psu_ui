"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file n6705_ui/presentation/models/time_series_model.py
@brief Qt table model used for time-series chart data.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""
from __future__ import annotations

from PySide6.QtCore import QAbstractTableModel, QModelIndex, Qt, Slot


class TimeSeriesTableModel(QAbstractTableModel):
    """Simple two-column table model for QtCharts VXYModelMapper.

    Column 0 -> X (seconds)
    Column 1 -> Y (value)
    """

    def __init__(self, max_points: int = 600) -> None:
        super().__init__()
        self._max_points = max(100, int(max_points))
        self._points: list[tuple[float, float]] = []

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: N802
        if parent.isValid():
            return 0
        return len(self._points)

    def columnCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: N802
        if parent.isValid():
            return 0
        return 2

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or role not in (Qt.DisplayRole, Qt.EditRole):
            return None

        x_val, y_val = self._points[index.row()]
        return x_val if index.column() == 0 else y_val

    @Slot(float, float)
    def append_point(self, x_value: float, y_value: float) -> None:
        if len(self._points) >= self._max_points:
            self.beginRemoveRows(QModelIndex(), 0, 0)
            self._points.pop(0)
            self.endRemoveRows()

        row = len(self._points)
        self.beginInsertRows(QModelIndex(), row, row)
        self._points.append((float(x_value), float(y_value)))
        self.endInsertRows()

    @Slot()
    def clear(self) -> None:
        if not self._points:
            return
        self.beginResetModel()
        self._points.clear()
        self.endResetModel()




