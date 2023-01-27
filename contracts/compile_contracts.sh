#!/bin/bash

set -euo pipefail

npx truffle compile --config cfg/truffle-config.ethereum.js
npx truffle compile --config cfg/truffle-config.polygon.js
