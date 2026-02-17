"""
Finans App - Unified Web & Proxy Server
8080 portu üzerinden hem Flutter dosyalarını sunar hem de /api isteklerini Django'ya yönlendirir.
"""
import http.server
import urllib.request
import urllib.error
import sys
import os

BACKEND_URL = "http://localhost:2223"

class FinansHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        '': 'application/octet-stream',
        '.html': 'text/html',
        '.js': 'application/javascript',
        '.mjs': 'application/javascript',
        '.json': 'application/json',
        '.css': 'text/css',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.gif': 'image/gif',
        '.svg': 'image/svg+xml',
        '.ico': 'image/x-icon',
        '.wasm': 'application/wasm',
    }

    def do_GET(self):
        if self.path.startswith('/api'):
            self.proxy_request()
        else:
            super().do_GET()

    def do_POST(self):
        if self.path.startswith('/api'):
            self.proxy_request()
        else:
            self.send_error(405, "Method not allowed")

    def do_PUT(self):
        if self.path.startswith('/api'):
            self.proxy_request()
        else:
            self.send_error(405, "Method not allowed")

    def do_DELETE(self):
        if self.path.startswith('/api'):
            self.proxy_request()
        else:
            self.send_error(405, "Method not allowed")

    def proxy_request(self):
        target_url = f"{BACKEND_URL}{self.path}"
        
        # Read request body for POST/PUT
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else None

        # Build headers for backend
        headers = {key: value for key, value in self.headers.items() 
                   if key.lower() not in ('host', 'content-length')}

        try:
            req = urllib.request.Request(
                target_url,
                data=body,
                headers=headers,
                method=self.command
            )
            with urllib.request.urlopen(req, timeout=30) as response:
                self.send_response(response.status)
                for key, value in response.headers.items():
                    if key.lower() not in ('transfer-encoding', 'connection'):
                        self.send_header(key, value)
                self.end_headers()
                self.wfile.write(response.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_error(502, f"Backend error: {str(e)}")

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    directory = sys.argv[2] if len(sys.argv) > 2 else '.'
    
    if os.path.exists(directory):
        os.chdir(directory)
    
    server = http.server.HTTPServer(('0.0.0.0', port), FinansHandler)
    print(f"Finans Unified Server: http://localhost:{port}")
    print(f"API Forwarding: /api -> {BACKEND_URL}")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()
