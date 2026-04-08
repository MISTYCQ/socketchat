import socket
import threading

HOST = '0.0.0.0'
PORT = 12345

clients = []
usernames = {}

def broadcast(message, sender_socket=None):
    for client in clients:
        if client != sender_socket:  # ✅ prevents echo
            try:
                client.send(message.encode())
            except:
                clients.remove(client)

def handle_client(client_socket, addr):
    print(f"[+] Connected: {addr}")
    clients.append(client_socket)

    try:
        username = client_socket.recv(1024).decode().strip()
        usernames[client_socket] = username

        broadcast(f"[SERVER] {username} joined\n", client_socket)

        while True:
            data = client_socket.recv(1024)
            if not data:
                break

            message = data.decode().strip()
            print(f"{username}: {message}")

            broadcast(f"[{username}]: {message}\n", client_socket)

    except:
        pass

    print(f"[-] Disconnected: {addr}")
    clients.remove(client_socket)

    user = usernames.get(client_socket, "Unknown")
    broadcast(f"[SERVER] {user} left\n", client_socket)

    client_socket.close()


def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((HOST, PORT))
    server.listen()

    print(f"Running on {HOST}:{PORT}")

    while True:
        client_socket, addr = server.accept()
        thread = threading.Thread(
            target=handle_client,
            args=(client_socket, addr)
        )
        thread.start()


if __name__ == "__main__":
    try:
        start_server()
    except KeyboardInterrupt:
        print("\n[*] Server shutting down.")