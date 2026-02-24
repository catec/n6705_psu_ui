"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file n6705_ui/communication/scpi_client.py
@brief SCPI-over-TCP transport client with synchronized IO.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""
from __future__ import annotations

import socket
import threading
from typing import Optional


class ScpiTcpClient:
    """Minimal SCPI-over-TCP client.

    The N6705 data socket listens on TCP port 5025 and expects commands
    terminated with newline (\n).
    """

    def __init__(self, host: str, port: int = 5025, timeout_s: float = 3.0) -> None:
        self._host = host
        self._port = port
        self._timeout_s = timeout_s
        self._socket: Optional[socket.socket] = None
        self._io_lock = threading.Lock()

    @property
    def host(self) -> str:
        return self._host

    @property
    def port(self) -> int:
        return self._port

    @property
    def is_connected(self) -> bool:
        return self._socket is not None

    def connect(self) -> None:
        if self._socket is not None:
            return

        sock = socket.create_connection((self._host, self._port), timeout=self._timeout_s)
        sock.settimeout(self._timeout_s)
        self._socket = sock

    def disconnect(self) -> None:
        sock = self._socket
        self._socket = None
        if sock is not None:
            try:
                sock.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            finally:
                sock.close()

    def write(self, command: str) -> None:
        payload = self._format_command(command)
        with self._io_lock:
            self._sendall(payload)

    def query(self, command: str) -> str:
        payload = self._format_command(command)
        with self._io_lock:
            self._sendall(payload)
            data = self._readline()
        return data

    def _sendall(self, payload: bytes) -> None:
        if self._socket is None:
            raise ConnectionError("No active TCP connection to the instrument")
        self._socket.sendall(payload)

    def _readline(self) -> str:
        if self._socket is None:
            raise ConnectionError("No active TCP connection to the instrument")

        buffer = bytearray()
        while True:
            chunk = self._socket.recv(4096)
            if not chunk:
                raise ConnectionError("TCP connection closed by the instrument")
            buffer.extend(chunk)
            if b"\n" in chunk:
                break

        line, _, _ = buffer.partition(b"\n")
        return line.decode("ascii", errors="replace").strip()

    @staticmethod
    def _format_command(command: str) -> bytes:
        normalized = command.rstrip("\r\n") + "\n"
        return normalized.encode("ascii")




