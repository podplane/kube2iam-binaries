#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://api.github.com/repos/jtblin/kube2iam/releases/latest \
  | jq -r '.tag_name'
