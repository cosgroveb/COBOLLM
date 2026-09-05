#!/usr/bin/env python3
"""Run TSTNET against controlled loopback TCP and TLS peers."""

from __future__ import annotations

import os
import socket
import ssl
import struct
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path


REQUEST = b"GET / HTTP/1.1\r\nAuthorization: test\r\n\r\n"


def make_certificate(directory: Path, name: str) -> tuple[Path, Path, Path]:
    ca_key = directory / f"{name}-ca.key"
    ca_cert = directory / f"{name}-ca.pem"
    key = directory / f"{name}.key"
    request = directory / f"{name}.csr"
    cert = directory / f"{name}.pem"
    extensions = directory / f"{name}.ext"
    extensions.write_text(
        "basicConstraints=critical,CA:FALSE\n"
        "keyUsage=critical,digitalSignature,keyEncipherment\n"
        "extendedKeyUsage=serverAuth\n"
        "subjectAltName=DNS:localhost\n",
        encoding="ascii",
    )
    quiet = {"stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL}
    subprocess.run(
        [
            "openssl",
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-nodes",
            "-keyout",
            str(ca_key),
            "-out",
            str(ca_cert),
            "-days",
            "3650",
            "-subj",
            f"/CN=COBOLLM {name} test CA",
            "-addext",
            "basicConstraints=critical,CA:TRUE",
            "-addext",
            "keyUsage=critical,keyCertSign,cRLSign",
        ],
        check=True,
        **quiet,
    )
    subprocess.run(
        [
            "openssl",
            "req",
            "-newkey",
            "rsa:2048",
            "-nodes",
            "-keyout",
            str(key),
            "-out",
            str(request),
            "-subj",
            "/CN=localhost",
        ],
        check=True,
        **quiet,
    )
    subprocess.run(
        [
            "openssl",
            "x509",
            "-req",
            "-in",
            str(request),
            "-CA",
            str(ca_cert),
            "-CAkey",
            str(ca_key),
            "-CAcreateserial",
            "-out",
            str(cert),
            "-days",
            "3650",
            "-extfile",
            str(extensions),
        ],
        check=True,
        **quiet,
    )
    return ca_cert, cert, key


class Peer(threading.Thread):
    def __init__(
        self,
        response: bytes = b"",
        *,
        tls_context: ssl.SSLContext | None = None,
        connections: int = 1,
        reset: bool = False,
    ) -> None:
        super().__init__(daemon=True)
        self.response = response
        self.tls_context = tls_context
        self.connections = connections
        self.reset = reset
        self.application_bytes: list[bytes] = []
        self.errors: list[str] = []
        self.listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.listener.bind(("127.0.0.1", 0))
        self.listener.listen(connections)
        self.listener.settimeout(20)
        self.port = self.listener.getsockname()[1]

    def run(self) -> None:
        try:
            for _ in range(self.connections):
                raw, _ = self.listener.accept()
                raw.settimeout(10)
                if self.reset:
                    raw.setsockopt(
                        socket.SOL_SOCKET,
                        socket.SO_LINGER,
                        struct.pack("ii", 1, 0),
                    )
                    raw.close()
                    self.application_bytes.append(b"")
                    continue
                stream: socket.socket | ssl.SSLSocket = raw
                if self.tls_context is not None:
                    try:
                        stream = self.tls_context.wrap_socket(
                            raw, server_side=True
                        )
                    except ssl.SSLError:
                        raw.close()
                        self.application_bytes.append(b"")
                        continue
                received = bytearray()
                while len(received) < len(REQUEST):
                    part = stream.recv(2)
                    if not part:
                        break
                    received.extend(part)
                self.application_bytes.append(bytes(received))
                for byte in self.response:
                    stream.sendall(bytes((byte,)))
                    time.sleep(0.001)
                if isinstance(stream, ssl.SSLSocket):
                    try:
                        stream.unwrap().close()
                    except (OSError, ssl.SSLError):
                        stream.close()
                else:
                    stream.shutdown(socket.SHUT_WR)
                    stream.close()
        except Exception as error:  # surfaced by main after every join
            self.errors.append(f"{type(error).__name__}: {error}")
        finally:
            self.listener.close()


def server_context(cert: Path, key: Path) -> ssl.SSLContext:
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.load_cert_chain(cert, key)
    return context


def main() -> int:
    if len(sys.argv) not in (2, 3, 4):
        print(
            "usage: netserver.py TEST-NET [TEST-RESOLVER [TEST-TLS-CLOSE]]",
            file=sys.stderr,
        )
        return 2
    executable = Path(sys.argv[1]).resolve()
    resolver = Path(sys.argv[2]).resolve() if len(sys.argv) >= 3 else None
    tls_close = Path(sys.argv[3]).resolve() if len(sys.argv) == 4 else None
    with tempfile.TemporaryDirectory(prefix="cobollm-net-") as temp:
        directory = Path(temp)
        trusted_ca, trusted_cert, trusted_key = make_certificate(
            directory, "trusted"
        )
        _, untrusted_cert, untrusted_key = make_certificate(
            directory, "untrusted"
        )
        trusted = server_context(trusted_cert, trusted_key)
        untrusted = server_context(untrusted_cert, untrusted_key)
        plain = Peer(b"PLAIN-OK")
        tls_ok = Peer(
            b"TLS-CLOSE-OK", tls_context=trusted, connections=2
        )
        mismatch = Peer(tls_context=trusted)
        bad_trust = Peer(tls_context=untrusted)
        reset = Peer(reset=True)
        resolver_peer = Peer(connections=3) if resolver else None
        close_peer = (
            Peer(tls_context=trusted, connections=2) if tls_close else None
        )
        peers = [plain, tls_ok, mismatch, bad_trust, reset]
        if resolver_peer:
            peers.append(resolver_peer)
        if close_peer:
            peers.append(close_peer)
        for peer in peers:
            peer.start()
        environment = os.environ.copy()
        environment.update(
            {
                "SSL_CERT_FILE": str(trusted_ca),
                "COBOLLM_TEST_PLAIN_PORT": str(plain.port),
                "COBOLLM_TEST_TLS_PORT": str(tls_ok.port),
                "COBOLLM_TEST_MISMATCH_PORT": str(mismatch.port),
                "COBOLLM_TEST_UNTRUSTED_PORT": str(bad_trust.port),
                "COBOLLM_TEST_RESET_PORT": str(reset.port),
            }
        )
        if resolver_peer:
            environment["COBOLLM_TEST_RESOLVE_PORT"] = str(
                resolver_peer.port
            )
        if close_peer:
            environment["COBOLLM_TEST_TLS_CLOSE_PORT"] = str(
                close_peer.port
            )
        try:
            result = subprocess.run(
                [str(executable)],
                env=environment,
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
            )
        except subprocess.TimeoutExpired:
            print("TSTNET timed out", file=sys.stderr)
            return 1
        resolver_result = None
        if resolver:
            try:
                resolver_result = subprocess.run(
                    [str(resolver)],
                    env=environment,
                    capture_output=True,
                    text=True,
                    timeout=30,
                    check=False,
                )
            except subprocess.TimeoutExpired:
                print("TSTRESLV timed out", file=sys.stderr)
                return 1
        tls_close_result = None
        if tls_close:
            try:
                tls_close_result = subprocess.run(
                    [str(tls_close)],
                    env=environment,
                    capture_output=True,
                    text=True,
                    timeout=30,
                    check=False,
                )
            except subprocess.TimeoutExpired:
                print("TSTTLSCL timed out", file=sys.stderr)
                return 1
        for peer in peers:
            peer.join(timeout=12)
        failures: list[str] = []
        if result.returncode != 0:
            failures.append(f"TSTNET returned {result.returncode}")
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        if resolver_result:
            if resolver_result.returncode != 0:
                failures.append(
                    f"TSTRESLV returned {resolver_result.returncode}"
                )
            if resolver_result.stdout:
                print(resolver_result.stdout, end="")
            if resolver_result.stderr:
                print(resolver_result.stderr, end="", file=sys.stderr)
        if tls_close_result:
            if tls_close_result.returncode != 0:
                failures.append(
                    f"TSTTLSCL returned {tls_close_result.returncode}"
                )
            if tls_close_result.stdout:
                print(tls_close_result.stdout, end="")
            if tls_close_result.stderr:
                print(tls_close_result.stderr, end="", file=sys.stderr)
        peer_names = ["plain", "tls", "mismatch", "untrusted", "reset"]
        if resolver_peer:
            peer_names.append("resolver")
        if close_peer:
            peer_names.append("tls-close")
        for name, peer in zip(peer_names, peers):
            if peer.is_alive():
                failures.append(f"{name} peer did not finish")
            failures.extend(f"{name}: {error}" for error in peer.errors)
        if plain.application_bytes != [REQUEST]:
            failures.append("plaintext peer received wrong application bytes")
        if tls_ok.application_bytes != [REQUEST, REQUEST]:
            failures.append(
                "trusted TLS peer received wrong application bytes: "
                f"{tls_ok.application_bytes!r}"
            )
        if mismatch.application_bytes != [b""]:
            failures.append("hostname mismatch leaked application bytes")
        if bad_trust.application_bytes != [b""]:
            failures.append("trust mismatch leaked application bytes")
        if resolver_peer and resolver_peer.application_bytes != [b""] * 3:
            failures.append("resolver peer received application bytes")
        if close_peer and close_peer.application_bytes != [b""] * 2:
            failures.append("TLS close peer received application bytes")
        if failures:
            for failure in failures:
                print(f"FAIL NET SERVER: {failure}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
