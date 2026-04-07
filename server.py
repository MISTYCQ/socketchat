"""
Chat Server - Socket Programming (Computer Networks)
Run this first: python server.py
"""

import socket
import threading

HOST = '127.0.0.1'
PORT = 12345
MAX_CLIENTS = 10

clients = {}   # {conn: username}
lock = threading.Lock()


def broadcast(message: str, sender_conn=None):
    """Send a message to all connected clients except the sender."""
    with lock:
        dead = []
        for conn in clients:
            if conn != sender_conn:
                try:
                    conn.sendall(message.encode('utf-8'))
                except OSError:
                    dead.append(conn)
        for conn in dead:
            _remove_client(conn)


def _remove_client(conn):
    """Remove a client (must be called with lock held)."""
    username = clients.pop(conn, None)
    try:
        conn.close()
    except OSError:
        pass
    return username


def handle_client(conn: socket.socket, addr):
    """Handle all communication with a single client."""
    print(f"[+] New connection from {addr}")

    # --- Handshake: receive username ---
    try:
        username = conn.recv(1024).decode('utf-8').strip()
        if not username:
            conn.close()
            return
    except OSError:
        conn.close()
        return

    with lock:
        clients[conn] = username

    join_msg = f"[SERVER] {username} joined the chat! ({len(clients)} online)"
    print(join_msg)
    broadcast(join_msg, sender_conn=conn)
    conn.sendall(f"[SERVER] Welcome, {username}! Type your message and press Enter.\n".encode())

    # --- Main receive loop ---
    try:
        while True:
            data = conn.recv(4096)
            if not data:
                break
            message = data.decode('utf-8').strip()
            if not message:
                continue
            if message.lower() == '/quit':
                break

            formatted = f"[{username}]: {message}"
            print(formatted)
            broadcast(formatted, sender_conn=conn)
    except OSError:
        pass
    finally:
        with lock:
            username = _remove_client(conn)
        leave_msg = f"[SERVER] {username} left the chat."
        print(leave_msg)
        broadcast(leave_msg)


def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(MAX_CLIENTS)
    print(f"[*] Server listening on {HOST}:{PORT}")
    print("[*] Waiting for connections... (Ctrl+C to stop)\n")

    try:
        while True:
            conn, addr = server.accept()
            t = threading.Thread(target=handle_client, args=(conn, addr), daemon=True)
            t.start()
    except KeyboardInterrupt:
        print("\n[*] Server shutting down.")
    finally:
        server.close()


if __name__ == '__main__':
    start_server()