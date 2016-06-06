import socket
from struct import pack, unpack, calcsize
from tornado import ioloop, iostream

class Client(object):

    server_port = 10659

    def __init__(self, server_addr, device_keys, device_fmt, loop):
        '''
        device_key is a mapping from device_id to a string of device key
        '''
        self.server_addr = server_addr
        self.device_keys = device_keys
        self.device_fmt = device_fmt
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0)
        self.stream = iostream.IOStream(s)

    def connect(self):
        self.stream.connect((self.server_addr, self.server_port), self.login)

    def login(self):
        print("connected")
        data = bytes()
        for x, key in self.device_keys.items():
            packet = pack("<bL32s", 0x02, x, key.encode())
            data += packet
        print(data)
        self.stream.write(data)
        self.stream.read_bytes(len(self.device_keys), self.on_login_complete)

    def on_login_complete(self, data):
        if any(data):
            print("login failed")
        else:
            print("login succeeded")
        self.stream.read_bytes(5, self.on_control_received)

    def logout(self):
        self.stream.write(pack("<b", 0x02), self.on_logout_complete)

    def on_logout_complete(self):
        print("logged out")
        self.strem.close()

    def report(self, device_id, ata):
        '''
        data is prepacked bytes!
        '''
        if device_id not in self.device_keys:
            print("device not registered")
            return
        packet = pack("<bLL", 0x03, device_id, 0)
        self.stream.write(packet + data)
        self.stream.read_bytes(1, self.on_report_complete)

    def on_report_complete(self, data):
        if any(data):
            print("report error")
        else:
            print("report success")
        self.stream.read_bytes(5, self.on_control_received)

    def on_control_received(self, data):
        code, device_id = unpack("<bL", data)
        print("control received for device {}".format(device_id))
        if device_id not in self.device_fmt:
            print("device is not in fmt")
            return
        self.waiting_device_id = device_id
        self.stream.read_bytes(calcsize(self.device_fmt[device_id]), self.on_control_received_bottom)

    def on_control_received_bottom(self, binary_data):
        '''
        to be determined whether control packet is of fixed size!
        '''
        data = unpack(self.device_fmt[self.waiting_device_id], binary_data)
        print(data)
        return data

keys = {9: "cc69c6a4aacb81385fdcbb41c61dd803"}
fmt = {9: "<ddb"}

def main():
    loop = ioloop.IOLoop.current()
    c = Client("nya.fatmou.se", keys, fmt, loop)
    c.connect()
    loop.start()

if __name__ == '__main__':
    main()
