import socket
import json
import threading
from input_handler import handle_mouse_move, handle_click, handle_scroll, handle_key, handle_text, handle_media

class WindpadServer:
    def __init__(self, port=8765, on_connect=None, on_disconnect=None):
        self.port = port
        self.server_socket = None
        self.running = False
        self.thread = None
        self.on_connect = on_connect
        self.on_disconnect = on_disconnect
        self.connected_clients = 0

    def start(self):
        self.running = True
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind(('0.0.0.0', self.port))
        self.server_socket.listen(5)
        
        self.thread = threading.Thread(target=self._accept_loop, daemon=True)
        self.thread.start()

    def stop(self):
        self.running = False
        if self.server_socket:
            try:
                self.server_socket.close()
            except Exception:
                pass

    def _accept_loop(self):
        while self.running:
            try:
                client_sock, addr = self.server_socket.accept()
                threading.Thread(target=self._handle_client, args=(client_sock,), daemon=True).start()
            except Exception:
                pass

    def _handle_client(self, client_sock):
        self.connected_clients += 1
        if self.on_connect and self.connected_clients == 1:
            self.on_connect(client_sock.getpeername()[0])
            
        buffer = ""
        while self.running:
            try:
                data = client_sock.recv(4096).decode('utf-8')
                if not data:
                    break
                
                buffer += data
                while '\n' in buffer:
                    line, buffer = buffer.split('\n', 1)
                    if line.strip():
                        self._process_command(line.strip(), client_sock)
            except Exception as e:
                break
        try:
            client_sock.close()
        except:
            pass
            
        self.connected_clients -= 1
        if self.on_disconnect and self.connected_clients == 0:
            self.on_disconnect()

    def _process_command(self, cmd_str, client_sock):
        try:
            cmd = json.loads(cmd_str)
            cmd_type = cmd.get('type')
            
            if cmd_type == 'ping':
                client_sock.sendall(json.dumps({'type': 'pong'}).encode() + b'\n')
            elif cmd_type == 'mouse_move':
                handle_mouse_move(cmd.get('dx', 0), cmd.get('dy', 0))
            elif cmd_type == 'mouse_click':
                handle_click(cmd.get('button', 'left'), cmd.get('action', 'click'))
            elif cmd_type == 'scroll':
                handle_scroll(cmd.get('dx', 0), cmd.get('dy', 0))
            elif cmd_type == 'key':
                handle_key(cmd.get('modifier', 0), cmd.get('keycode', 0))
            elif cmd_type == 'text':
                handle_text(cmd.get('content', ''))
            elif cmd_type == 'media':
                handle_media(cmd.get('action', ''))
        except Exception as e:
            pass
