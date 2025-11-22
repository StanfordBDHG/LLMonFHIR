#
# This source file is part of the Stanford LLM on FHIR project
#
# SPDX-FileCopyrightText: 2025 Stanford University
#
# SPDX-License-Identifier: MIT
#

import argparse
from cryptography.hazmat.primitives.asymmetric import x25519
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from pathlib import Path
import sys
import base64
import typing

def decrypt(key: x25519.X25519PrivateKey, input: bytes) -> bytes:
    ephemeral_public_key_data = input[:32]
    ciphertext = input[32:]
    ephemeral_public_key = x25519.X25519PublicKey.from_public_bytes(ephemeral_public_key_data)
    shared_secret = key.exchange(ephemeral_public_key)
    kdf = HKDF(algorithm=hashes.SHA256(), length=32, salt=b'', info=b'')
    symmetric_key = kdf.derive(shared_secret)
    aesgcm = AESGCM(symmetric_key)
    plaintext = aesgcm.decrypt(ciphertext[:12], ciphertext[12:], None)
    return plaintext

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='DecryptLLMonFHIRStudyReport',
        description='Decrypts encrypted study reports from the LLMonFHIR app'
    )
    parser.add_argument('-k', '--key', type=Path, required=True, help='the private key for decrypting the file')
    parser.add_argument('-i', '--in-place', action='store_true',
                        help='whether the output should be written to the input file, replacing the previous (encrypted) contents. ignored if the input is piped in via STDIN')
    parser.add_argument('file', type=Path, help='the file to decrypt')
    args = parser.parse_args()
    key_bytes: bytes = typing.cast(Path, args.key).read_bytes().split(b'\n')[1]
    key_bytes = base64.decodebytes(key_bytes)[-32:]
    key = x25519.X25519PrivateKey.from_private_bytes(key_bytes)
    file: Path = args.file
    input_is_stdin = file == Path('-')
    input: bytes = sys.stdin.buffer.read() if input_is_stdin else file.read_bytes()
    output = decrypt(key, input)
    if not input_is_stdin and args.in_place:
        file.write_bytes(output)
    else:
        print(output.decode())
