#!/usr/bin/env python

'''Farmware Tools: Farmware API utilities used by `device` for FarmBot OS v8.'''

import sys
import json
import struct
import socket
import threading
from time import time, sleep
from uuid import uuid4
try:
    import paho.mqtt.client as mqtt
except ImportError:
    pass
from .env import Env

ENV = Env()
HEADER_FORMAT = '>HII'
TIMEOUT_SECONDS = 10


def _open_socket(address):
    opened_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    opened_socket.settimeout(TIMEOUT_SECONDS)
    try:
        opened_socket.connect(address)
    except FileNotFoundError:
        print('Could not connect to socket: address not found.')
        sys.exit(1)
    return opened_socket


class _ResponseBuffer():
    '''Collection of responses from FarmBot OS.'''

    def __init__(self):
        self.responses = {}
        self.response_socket = _open_socket(ENV.response_pipe)

    def listen(self):
        '''Collect responses from FarmBot OS.'''
        while True:
            try:
                header = self.response_socket.recv(10)
            except socket.timeout:
                continue
            if header == b'':
                continue
            (_, _, size) = struct.unpack(HEADER_FORMAT, header)
            response = json.loads(self.response_socket.recv(size).decode())
            self.responses[response['args']['label']] = response

    def pop(self, rpc_uuid):
        '''Pull a response off of the buffer by RPC UUID (label).'''
        wait_time = 0
        while wait_time < TIMEOUT_SECONDS:
            response = self.responses.pop(rpc_uuid, None)
            if response is None:
                wait_time += 0.5
                sleep(0.5)
            else:
                return response
        return 'no response'


# Listen for responses from FarmBot OS.
if ENV.use_v2() and ENV.farmware_api_available():
    RESPONSE_BUFFER = _ResponseBuffer()
    RESPONSES = threading.Thread(target=RESPONSE_BUFFER.listen, daemon=True)
    RESPONSES.start()
elif ENV.use_mqtt():
    RESPONSES = {}
    STATUS = {}
    client = mqtt.Client()

    def _on_message(_client, _userdata, msg):
        message = json.loads(msg.payload)
        if 'status' in msg.topic:
            for key, value in message.items():
                STATUS[key] = value
        elif message.get('kind') in ['rpc_ok', 'rpc_error']:
            rpc_id = message.get('args', {}).get('label')
            if rpc_id is not None:
                RESPONSES[rpc_id] = message
    client.on_message = _on_message
    client.username_pw_set(ENV.decoded_token['bot'], password=ENV.token)
    try:
        client.connect(ENV.decoded_token['mqtt'])
    except:
        MQTT_OK = False
    else:
        MQTT_OK = True

    if MQTT_OK:
        def _mqtt_channel(channel):
            return 'bot/{}/{}'.format(ENV.decoded_token['bot'], channel)
        client.subscribe(_mqtt_channel('from_device'))
        client.subscribe(_mqtt_channel('status'))


def _mqtt_request(payload, wait_for_status=False):
    'Make a request via MQTT.'
    if not MQTT_OK:
        return 'no MQTT'
    if wait_for_status:
        STATUS.clear()
    client.loop_start()
    print(f'sending MQTT message: {json.dumps(payload, indent=2)}')
    sleep(0.5)
    client.publish(_mqtt_channel('from_clients'), payload=json.dumps(payload))
    rpc_id = payload.get('args', {}).get('label', '')
    start = time()
    response = 'no response'
    while (time() - start) < TIMEOUT_SECONDS:
        sleep(0.5)
        if wait_for_status:
            if len(STATUS.keys()) > 0:
                return 'got status'
        elif rpc_id in RESPONSES.keys():
            response = RESPONSES[rpc_id]
    print(f'MQTT response: {json.dumps(response, indent=2)}')
    client.loop_stop()
    return response


def _mqtt_status():
    'Fetch bot state via MQTT.'
    _mqtt_request({
        'kind': 'rpc_request',
        'args': {'label': str(uuid4())},
        'body': [{'kind': 'read_status', 'args': {}}]}, wait_for_status=True)
    return STATUS



def _request_write(payload):
    'Make a request to FarmBot OS.'
    request_socket = _open_socket(ENV.request_pipe)
    message_bytes = bytes(json.dumps(payload), 'utf-8')
    header = struct.pack(HEADER_FORMAT, 0xFBFB, 0, len(message_bytes))
    request_socket.sendall(header + message_bytes)
    request_socket.close()


def _response_read(rpc_uuid):
    'Read a response from FarmBot OS for the provided request RPC UUID.'
    if rpc_uuid is not None:
        return RESPONSE_BUFFER.pop(rpc_uuid)
    return 'missing RPC label'
