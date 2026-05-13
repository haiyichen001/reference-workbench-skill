#!/bin/bash
# Reference Workbench Skill — environment check
# Checks Python, rich, and MCP server availability

echo "=== Reference Workbench setup ==="

# Python check
if command -v python3 &>/dev/null; then
    PY=python3
elif command -v python &>/dev/null; then
    PY=python
else
    echo "MISSING: Python 3.10+ required"
    exit 1
fi

echo "Python: $($PY --version 2>&1)"

# Rich check
if $PY -c "import rich" 2>/dev/null; then
    echo "rich:   installed"
else
    echo "MISSING: pip install rich"
fi

# MCP check — we can't check from bash, Claude will verify
echo "MCP:    Claude will verify arxiv/scholar/paper-search/pdf-reader"

echo "Setup complete."
