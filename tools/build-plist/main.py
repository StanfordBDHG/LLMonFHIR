#
# This source file is part of the Stanford LLM on FHIR project
#
# SPDX-FileCopyrightText: 2026 Stanford University
#
# SPDX-License-Identifier: MIT
#

# `uv run main.py -h`

import argparse
from pathlib import Path
import plistlib
import typing


parser = argparse.ArgumentParser(
    prog='build-plist',
    description='Builds the LLMonFHIR config plist'
)
parser.add_argument('-f', '--firebase-config', type=Path, required=False, help='the firebase GoogleService-Info.plist file')
parser.add_argument('-o', '--openai-api-key', type=str, required=True, help='the OpenAI API key to be used for study-related API requests')
parser.add_argument('-k', '--encryption-public-key', type=Path, help='path to the public_key.pem that should be used to encrypt the study reports')
parser.add_argument('input', type=Path, help='input file (the UserStudyConfig.plist)')
parser.add_argument('output', type=Path, nargs='?', help='output file. defaults to input if omitted')
args = parser.parse_args()

config = plistlib.loads(typing.cast(Path, args.input).read_bytes())

public_key_data: bytes
if key_path := typing.cast(Path, args.encryption_public_key):
    public_key_data = key_path.read_bytes()
else:
    public_key_data = bytes()

for study in config['studies']:
    study['openai_api_key'] = args.openai_api_key
    study['encryption_key'] = public_key_data

if firebase_plist := typing.cast(Path, args.firebase_config):
    config['firebase_config'] = plistlib.loads(firebase_plist.read_bytes())

with typing.cast(Path, args.output or args.input).open('wb') as f:
    plistlib.dump(config, f)
