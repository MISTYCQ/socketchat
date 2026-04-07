"""
Chat Client - Socket Programming (Computer Networks)
Run after server: python client.py
"""

import socket
import threading
import sys

HOST = '127.0.0.1'
PORT = 12345


def receive_messages(sock: socket.socket):
    """Background thread: continuously print incoming messages."""
    while True:
        try:
            data = sock.recv(4096)
            if not data:
                print("\n[!] Connection closed by server.")
                break
            print(data.decode('utf-8'))
        except OSError:
            break


def start_client():
    username = input("Enter your username: ").strip()
    if not username:
        print("[!] Username cannot be empty.")
        sys.exit(1)

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    try:
        sock.connect((HOST, PORT))
        print(f"[*] Connected to {HOST}:{PORT}\n")
    except ConnectionRefusedError:
        print(f"[!] Could not connect to {HOST}:{PORT}. Is the server running?")
        sys.exit(1)

    # Send username to server as handshake
    sock.sendall(username.encode('utf-8'))

    # Start background thread to receive messages
    recv_thread = threading.Thread(target=receive_messages, args=(sock,), daemon=True)
    recv_thread.start()

    
    print("Type a message and press Enter. Type /quit to exit.\n")
    try:
        while True:
            msg = input()
            if not msg:
                continue
            sock.sendall(msg.encode('utf-8'))
            if msg.lower() == '/quit':
                print("[*] Disconnecting...")
                break
    except (KeyboardInterrupt, EOFError):
        print("\n[*] Disconnecting...")
    finally:
        sock.close()


if __name__ == '__main__':
    start_client()