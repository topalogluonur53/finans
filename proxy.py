"""
Finans App - Reverse Proxy
Tek port uzerinden hem Flutter Web hem Django API sunar.
Cloudflare Tunnel bu porta yonlendirilmelidir.

/api/*  -> Django Backend (localhost:2223)
/*      -> Flutter Web App (localhost:8080)
"""

import http.server
import http.client
import sys
import threading

LISTEN_PORT = 3000
FLUTTER_HOST = "localhost"
FLUTTER_PORT = 8080
DJANGO_HOST = "localhost"
DJANGO_PORT = 2223


class ReverseProxyHandler(http.server.BaseHTTPRequestHandler):
    def _proxy(self):
        # Determine target
        if self.path.startswith('/api'):
            target_host = DJANGO_HOST
            target_port = DJANGO_PORT
        else:
            target_host = FLUTTER_HOST
            target_port = FLUTTER_PORT

        # Read request body
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else None

        try:
            # Connect to target
            conn = http.client.HTTPConnection(target_host, target_port, timeout=15)

            # Forward headers (skip hop-by-hop)
            headers = {}
            for key, value in self.headers.items():
                lk = key.lower()
                if lk not in ('host', 'transfer-encoding', 'connection', 'keep-alive'):
                    headers[key] = value
            headers['Host'] = f'{target_host}:{target_port}'

            # Make request
            conn.request(self.command, self.path, body=body, headers=headers)
            resp = conn.getresponse()

            # Send response status
            self.send_response_only(resp.status)

            # Forward response headers
            for key, value in resp.getheaders():
                lk = key.lower()
                if lk not in ('transfer-encoding', 'connection', 'keep-alive'):
                    self.send_header(key, value)
            self.end_headers()

            # Forward response body
            try:
                data = resp.read()
                if data:
                    self.wfile.write(data)
            except Exception:
                pass

            conn.close()

        except ConnectionRefusedError:
            self._send_error(502, "Backend baglantisi reddedildi")
        except TimeoutError:
            self._send_error(504, "Backend zaman asimina ugradi")
        except Exception as e:
            self._send_error(500, f"Proxy hatasi: {type(e).__name__}: {e}")

    def _send_error(self, code, message):
        try:
            body = message.encode('utf-8')
            self.send_response_only(code)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except Exception:
            pass

    def do_GET(self):
        self._proxy()

    def do_POST(self):
        self._proxy()

    def do_PUT(self):
        self._proxy()

    def do_PATCH(self):
        self._proxy()

    def do_DELETE(self):
        self._proxy()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Access-Control-Max-Age', '86400')
        self.end_headers()

    def log_message(self, format, *args):
        target = "Django" if self.path.startswith('/api') else "Flutter"
        sys.stderr.write(f"[{target}] {format % args}\n")


class ThreadedHTTPServer(http.server.HTTPServer):
    allow_reuse_address = True
    daemon_threads = True

    def process_request(self, request, client_address):
        t = threading.Thread(target=self._new_request, args=(request, client_address))
        t.daemon = True
        t.start()

    def _new_request(self, request, client_address):
        try:
            self.finish_request(request, client_address)
        except Exception:
            pass
        finally:
            self.shutdown_request(request)


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else LISTEN_PORT
    server = ThreadedHTTPServer(('0.0.0.0', port), ReverseProxyHandler)
    print("========================================================")
    print("          Finans App - Reverse Proxy")
    print("========================================================")
    print(f"  Proxy     : http://0.0.0.0:{port}")
    print(f"  Flutter   : http://{FLUTTER_HOST}:{FLUTTER_PORT}")
    print(f"  Django API: http://{DJANGO_HOST}:{DJANGO_PORT}")
    print("--------------------------------------------------------")
    print("  /api/*  -> Django Backend")
    print("  /*      -> Flutter Web App")
    print("--------------------------------------------------------")
    print(f"  Cloudflare Tunnel bu porta yonlendirilmeli:")
    print(f"  http://localhost:{port}")
    print("========================================================")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nProxy kapatiliyor...")
        server.shutdown()


if __name__ == '__main__':
    main()
