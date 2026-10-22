"""Disposable servers for differential rendering checks (Linux Docker host paths)."""

from contextlib import closing
import gzip
import http.client
import json
import os
from pathlib import Path
import shutil
import socket
import sqlite3
import tempfile
import time
from urllib.parse import urlencode
import uuid

from benchmark_shared import command

IMAGES = {
    "rust": "sha256:98ba156f688c3fe856afd71655f613a6620bc03754f456ed2ef08fb2e5527e6e",
    "jai": "sha256:014651a89f16953fab46cc3f322019d932d37ff1a098d98fb71bdf2e976caf92",
    "goose": "goose-campfire-toolchain:latest",
}


class Server:
    def __init__(self, app, seed, runtime, output, cache=True, binary="campfire"):
        self.app, self.seed, self.output = app, Path(seed).resolve(), Path(output).resolve()
        self.binary = binary
        self.repo = Path(__file__).resolve().parents[2]
        self.temporary = tempfile.TemporaryDirectory(prefix=f"render-{app}-", dir=Path(runtime).resolve())
        self.data = Path(self.temporary.name)
        self.database = self.data / "db/production.sqlite3"
        self.name = f"goose-render-{app}-{uuid.uuid4().hex[:10]}"
        self.cache, self.cookie, self.port = cache, "", 0
        self.labels = json.loads((self.seed / "labels.json").read_text())

    def __enter__(self):
        try:
            for folder in ("db", "logs"):
                (self.data / folder).mkdir(mode=0o777)
                os.chmod(self.data / folder, 0o777)
            shutil.copytree(self.seed / "storage", self.data / "files")
            with closing(sqlite3.connect((self.seed / "db/production.sqlite3").as_uri() + "?mode=ro", uri=True)) as source:
                with closing(sqlite3.connect(self.database)) as target:
                    source.backup(target)
                    target.executescript("UPDATE push_subscriptions SET endpoint='https://127.0.0.1:9/push/'||id; "
                                         "UPDATE webhooks SET url='http://127.0.0.1:9/hook/'||id;")
            os.chmod(self.database, 0o666)
            os.chmod(self.data, 0o755)
            with socket.socket() as sock:
                sock.bind(("127.0.0.1", 0))
                self.port = sock.getsockname()[1]
            env = dict(line.split("=", 1) for line in (self.seed / "reference.env").read_text().splitlines()
                       if line and not line.startswith("#"))
            env.update(PORT=str(self.port), HTTP_PORT=str(self.port), TARGET_PORT=str(self.port + 1),
                       DATABASE_PATH="/rails/storage/db/production.sqlite3", STORAGE_PATH="/rails/storage/files",
                       CAMPFIRE_CACHE="1" if self.cache else "0", CAMPFIRE_CACHE_DIAGNOSTICS="0",
                       RAILS_LOG_LEVEL="warn", WEB_CONCURRENCY="3", JOB_CONCURRENCY="3", RAILS_MAX_THREADS="5")
            env_file = self.data / "server.env"
            env_file.write_text("".join(f"{k}={v}\n" for k, v in env.items()))
            os.chmod(env_file, 0o600)
            args = ["docker", "run", "-d", "--name", self.name, "--network", "host", "--env-file", env_file]
            for folder in ("db", "files", "logs"):
                args += ["-v", f"{self.data / folder}:/rails/storage/{folder}"]
            if self.app == "goose":
                args += ["-v", f"{self.repo}:/app:ro", "--workdir", "/app"]
            args += [IMAGES[self.app]]
            if self.app == "goose":
                args += [f"/app/bench/campfire/build/{self.binary}"]
            command(*args)
            for _ in range(600):
                try:
                    if self.request("/up")[0] == 200:
                        break
                except (OSError, http.client.HTTPException):
                    pass
                time.sleep(.1)
            else:
                raise RuntimeError(f"{self.app}: startup timeout")
            self.login("david")
            return self
        except BaseException:
            self.__exit__(None, None, None)
            raise

    @property
    def base(self):
        return f"http://127.0.0.1:{self.port}"

    def request(self, path, data=None, headers=None, method=None):
        fields = {"Accept-Encoding": "gzip", "Cookie": self.cookie}
        if data is not None:
            fields.update({"Content-Type": "application/x-www-form-urlencoded", "Sec-Fetch-Site": "same-origin"})
        fields.update(headers or {})
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=15)
        try:
            conn.request(method or ("POST" if data is not None else "GET"), path, body=data, headers=fields)
            response = conn.getresponse()
            body = response.read()
            if method != "HEAD" and response.getheader("Content-Encoding") == "gzip":
                body = gzip.decompress(body)
            return response.status, dict(response.getheaders()), body
        finally:
            conn.close()

    def login(self, user):
        status, headers, _ = self.request("/session", urlencode({"email_address": self.labels[f"emails.{user}"],
                                                                "password": self.labels["passwords.all"]}))
        assert status == 302, (self.app, "login", status)
        self.cookie = next(v for k, v in headers.items() if k.lower() == "set-cookie").split(";", 1)[0]

    def __exit__(self, *exc):
        self.output.mkdir(parents=True, exist_ok=True)
        result = command("docker", "logs", self.name, check=False)
        (self.output / f"{self.app}.log").write_text(result.stdout + result.stderr)
        command("docker", "rm", "-f", self.name, check=False)
        self.temporary.cleanup()
