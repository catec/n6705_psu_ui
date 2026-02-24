"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file tests/test_scpi_client_integration.py
@brief Integration tests for SCPI transport and N6705 adapter.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""
from __future__ import annotations

import socketserver
import threading
import time
import unittest

from n6705_ui.communication.scpi_client import ScpiTcpClient
from n6705_ui.device.n6705 import N6705PowerAnalyzer


class _ScpiMockServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True

    def __init__(self, server_address, request_handler_class):
        super().__init__(server_address, request_handler_class)
        self.commands: list[str] = []
        self._lock = threading.Lock()

    def push_command(self, command: str) -> None:
        with self._lock:
            self.commands.append(command)

    def get_commands(self) -> list[str]:
        with self._lock:
            return list(self.commands)

    def clear_commands(self) -> None:
        with self._lock:
            self.commands.clear()


class _ScpiHandler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        buffer = b""
        while True:
            chunk = self.request.recv(4096)
            if not chunk:
                return
            buffer += chunk

            while b"\n" in buffer:
                line, buffer = buffer.split(b"\n", 1)
                command = line.decode("ascii", errors="replace").strip()
                if not command:
                    continue

                self.server.push_command(command)  # type: ignore[attr-defined]
                response = self._response_for(command)
                if response is not None:
                    self.request.sendall(response.encode("ascii"))

    @staticmethod
    def _response_for(command: str) -> str | None:
        if command == "*IDN?":
            return "KEYSIGHT,N6705B,MY00000001,B.00.00\n"
        if command == "SYST:CHAN?":
            return "+4\n"
        if command == "MEAS:VOLT? (@1)":
            return "+5.000000E+00\n"
        if command == "MEAS:CURR? (@1)":
            return "+1.000000E+00\n"
        if command == "MEAS:POW? (@1)":
            return "+5.000000E+00\n"
        if command == "MEAS:VOLT? (@2)":
            return "+3.000000E+00\n"
        if command == "MEAS:CURR? (@2)":
            return "+2.000000E+00\n"
        if command == "VOLT? (@1)":
            return "+5.000000E+00\n"
        if command == "CURR? (@1)":
            return "+1.000000E+00\n"
        if command == "VOLT? MIN,(@1)":
            return "+0.000000E+00\n"
        if command == "VOLT? MAX,(@1)":
            return "+2.000000E+01\n"
        if command == "CURR? MIN,(@1)":
            return "+0.000000E+00\n"
        if command == "CURR? MAX,(@1)":
            return "+5.000000E+00\n"
        if command == "OUTP? (@1)":
            return "1\n"
        return None


class ScpiClientIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.server = _ScpiMockServer(("127.0.0.1", 0), _ScpiHandler)
        cls.server_thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.server_thread.start()
        cls.host, cls.port = cls.server.server_address

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.server.server_close()
        cls.server_thread.join(timeout=2.0)

    def setUp(self) -> None:
        self.server.clear_commands()

    def test_query_idn(self) -> None:
        client = ScpiTcpClient(host=self.host, port=self.port, timeout_s=1.0)
        client.connect()
        try:
            response = client.query("*IDN?")
        finally:
            client.disconnect()

        self.assertIn("N6705B", response)
        self.assertEqual(self.server.get_commands()[-1], "*IDN?")

    def test_write_sends_scpi_command_line(self) -> None:
        client = ScpiTcpClient(host=self.host, port=self.port, timeout_s=1.0)
        client.connect()
        try:
            client.write("OUTP ON,(@1)")
            time.sleep(0.05)
        finally:
            client.disconnect()

        self.assertIn("OUTP ON,(@1)", self.server.get_commands())

    def test_driver_measure_channels(self) -> None:
        client = ScpiTcpClient(host=self.host, port=self.port, timeout_s=1.0)
        instrument = N6705PowerAnalyzer(client)
        instrument.connect()
        try:
            samples = instrument.measure_channels([1])
        finally:
            instrument.disconnect()

        self.assertEqual(len(samples), 1)
        sample = samples[0]
        self.assertEqual(sample.channel, 1)
        self.assertAlmostEqual(sample.voltage_v, 5.0, places=6)
        self.assertAlmostEqual(sample.current_a, 1.0, places=6)
        self.assertAlmostEqual(sample.power_w, 5.0, places=6)

    def test_driver_reports_channel_count(self) -> None:
        client = ScpiTcpClient(host=self.host, port=self.port, timeout_s=1.0)
        instrument = N6705PowerAnalyzer(client)
        instrument.connect()
        try:
            count = instrument.get_channel_count()
        finally:
            instrument.disconnect()

        self.assertEqual(count, 4)

    def test_driver_measure_channels_falls_back_when_power_query_not_supported(self) -> None:
        client = ScpiTcpClient(host=self.host, port=self.port, timeout_s=1.0)
        instrument = N6705PowerAnalyzer(client)
        instrument.connect()
        try:
            samples = instrument.measure_channels([2])
        finally:
            instrument.disconnect()

        self.assertEqual(len(samples), 1)
        sample = samples[0]
        self.assertEqual(sample.channel, 2)
        self.assertAlmostEqual(sample.voltage_v, 3.0, places=6)
        self.assertAlmostEqual(sample.current_a, 2.0, places=6)
        self.assertAlmostEqual(sample.power_w, 6.0, places=6)

    def test_driver_channel_limits_queries(self) -> None:
        client = ScpiTcpClient(host=self.host, port=self.port, timeout_s=1.0)
        instrument = N6705PowerAnalyzer(client)
        instrument.connect()
        try:
            v_min = instrument.get_voltage_min_limit(1)
            v_max = instrument.get_voltage_max_limit(1)
            i_min = instrument.get_current_min_limit(1)
            i_max = instrument.get_current_max_limit(1)
        finally:
            instrument.disconnect()

        self.assertAlmostEqual(v_min, 0.0, places=6)
        self.assertAlmostEqual(v_max, 20.0, places=6)
        self.assertAlmostEqual(i_min, 0.0, places=6)
        self.assertAlmostEqual(i_max, 5.0, places=6)


if __name__ == "__main__":
    unittest.main()




