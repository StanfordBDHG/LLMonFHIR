import argparse
from cryptography.hazmat.primitives.asymmetric import x25519
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from pathlib import Path
import sys
import base64
import typing

def decrypt(key: x25519.X25519PrivateKey, input: bytes):
    ephemeral_public_key_data = input[:32]
    ciphertext = input[32:]
    ephemeral_public_key = x25519.X25519PublicKey.from_public_bytes(ephemeral_public_key_data)
    shared_secret = key.exchange(ephemeral_public_key)
    kdf = HKDF(algorithm=hashes.SHA256(), length=32, salt=b'', info=b'')
    symmetric_key = kdf.derive(shared_secret)
    aesgcm = AESGCM(symmetric_key)
    plaintext = aesgcm.decrypt(ciphertext[:12], ciphertext[12:], None)
    print(plaintext)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='DecryptLLMonFHIRStudyReport',
        description='Decrypts encrypted study reports from the LLMonFHIR app'
    )
    parser.add_argument('filename', type=Path)
    parser.add_argument('-k', '--key', type=Path, required=True)
    args = parser.parse_args()
    key_bytes: bytes = typing.cast(Path, args.key).read_bytes().split(b'\n')[1]
    key_bytes = base64.decodebytes(key_bytes)[-32:]
    key = x25519.X25519PrivateKey.from_private_bytes(key_bytes)
    filename: Path = args.filename
    input: bytes = bytes(sys.stdin.read(), 'utf8') if filename == Path('-') else filename.read_bytes()
    input = base64.decodebytes(input)
    decrypt(key, input)