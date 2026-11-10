from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os
import time

STUDENT_ID = os.environ.get("STUDENT_ID", "102783255")


class BurnHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        started = time.perf_counter()

        while time.perf_counter() - started < 0.20:
            total = 0
            for number in range(1, 3000):
                total += number * number

        body = f"OK burn {STUDENT_ID}\n".encode()

        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format_string, *args):
        return


server = ThreadingHTTPServer(("0.0.0.0", 8080), BurnHandler)
server.serve_forever()
