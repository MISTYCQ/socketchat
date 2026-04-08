"""
Enhanced Chat Server - Socket Programming with Private Messaging
Run this first: python enhanced_server.py
"""

import socket
import threading
import json
import time

HOST = '127.0.0.1'
PORT = 12345
MAX_CLIENTS = 50

clients = {}   # {conn: {"username": str, "last_seen": float}}
lock = threading.Lock()


def get_online_users():
    """Get list of currently online users."""
    with lock:
        return [info["username"] for info in clients.values()]


def broadcast_user_list():
    """Send updated user list to all clients."""
    user_list = get_online_users()
    message = json.dumps({
        "type": "user_list",
        "users": user_list
    })
    with lock:
        dead = []
        for conn in clients:
            try:
                conn.sendall(f"{message}\n".encode('utf-8'))
            except OSError:
                dead.append(conn)
        for conn in dead:
            _remove_client(conn)


def broadcast_message(message: str, sender_conn=None):
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


def send_private_message(recipient: str, message: str, sender_username: str):
    """Send a private message to a specific user."""
    with lock:
        for conn, info in clients.items():
            if info["username"] == recipient:
                try:
                    msg = json.dumps({
                        "type": "private",
                        "from": sender_username,
                        "message": message,
                        "timestamp": time.time()
                    })
                    conn.sendall(f"{msg}\n".encode('utf-8'))
                    return True
                except OSError:
                    pass
        return False


def _remove_client(conn):
    """Remove a client (must be called with lock held)."""
    user_info = clients.pop(conn, None)
    try:
        conn.close()
    except OSError:
        pass
    return user_info


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

    # Check if username already exists
    with lock:
        existing_users = [info["username"] for info in clients.values()]
        if username in existing_users:
            error_msg = json.dumps({"type": "error", "message": "Username already taken"})
            conn.sendall(f"{error_msg}\n".encode('utf-8'))
            conn.close()
            return

    with lock:
        clients[conn] = {
            "username": username,
            "last_seen": time.time()
        }

    join_msg = f"[SERVER] {username} joined the chat! ({len(clients)} online)\n"
    print(join_msg.strip())
    
    # Send welcome message
    welcome = json.dumps({
        "type": "system",
        "message": f"Welcome, {username}! Type your message and press Enter."
    })
    conn.sendall(f"{welcome}\n".encode('utf-8'))
    
    # Broadcast user list to all clients
    broadcast_user_list()
    
    # Broadcast join message
    broadcast_message(join_msg, sender_conn=conn)

    # --- Main receive loop ---
    try:
        while True:
            data = conn.recv(4096)
            if not data:
                break
            
            raw_message = data.decode('utf-8').strip()
            if not raw_message:
                continue
            
            if raw_message.lower() == '/quit':
                break

            # Try to parse as JSON (for private messages)
            try:
                msg_data = json.loads(raw_message)
                
                if msg_data.get("type") == "private":
                    # Private message
                    recipient = msg_data.get("to")
                    message = msg_data.get("message")
                    
                    if send_private_message(recipient, message, username):
                        # Send confirmation back to sender
                        confirmation = json.dumps({
                            "type": "private_sent",
                            "to": recipient,
                            "message": message,
                            "timestamp": time.time()
                        })
                        conn.sendall(f"{confirmation}\n".encode('utf-8'))
                        print(f"[{username} → {recipient}]: {message}")
                    else:
                        error = json.dumps({
                            "type": "error",
                            "message": f"User {recipient} not found or offline"
                        })
                        conn.sendall(f"{error}\n".encode('utf-8'))
                
            except json.JSONDecodeError:
                # Regular broadcast message
                formatted = f"[{username}]: {raw_message}\n"
                print(formatted.strip())
                broadcast_message(formatted, sender_conn=conn)
            
            # Update last seen
            with lock:
                if conn in clients:
                    clients[conn]["last_seen"] = time.time()
                    
    except OSError:
        pass
    finally:
        with lock:
            user_info = _remove_client(conn)
            username = user_info["username"] if user_info else "Unknown"
        
        leave_msg = f"[SERVER] {username} left the chat.\n"
        print(leave_msg.strip())
        broadcast_message(leave_msg)
        broadcast_user_list()


def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(MAX_CLIENTS)
    print(f"[*] Enhanced Server listening on {HOST}:{PORT}")
    print("[*] Features: Private messaging, User list, Username storage")
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