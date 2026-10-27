#!/usr/bin/env bash
# Deterministic gate for agent tool calls.
#
# Wired up by .github/hooks/copilot-hooks.json as a preToolUse hook. It runs
# before an agent executes a bash command, and a non-zero exit denies the call
# no matter how confidently the agent wanted to proceed.
#
# It deliberately runs the SAME checks as .githooks/pre-commit rather than a
# parallel set. Two copies of a rule drift; one copy does not.

set -uo pipefail

# The layering rule. Cheap, and the one agents break most often.
if grep -rn "package:flutter/" lib/domain/ 2>/dev/null; then
  echo "DENIED: lib/domain must stay pure Dart — no package:flutter import."
  echo "Fix the import before running another command."
  exit 1
fi

# Credentials, whether staged or merely written to disk.
if git status --porcelain 2>/dev/null | grep -qE 'google-services\.json|GoogleService-Info\.plist|\.keystore$|\.jks$|\.p12$'; then
  echo "DENIED: a credential or platform config file is in the working tree."
  echo "These belong in repository secrets, not in git history."
  exit 1
fi

# Everything the git hook checks, so an agent cannot route around it.
if [ -x .githooks/pre-commit ]; then
  .githooks/pre-commit || {
    echo "DENIED: .githooks/pre-commit failed. Fix the finding above."
    exit 1
  }
fi

exit 0
