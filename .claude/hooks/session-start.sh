#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web (remote/cloud environments)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
SKILL_DIR="${HOME}/.claude/skills/seo"
AGENT_DIR="${HOME}/.claude/agents"

echo "→ Installing Claude SEO skills globally..."

# Create target directories
mkdir -p "${SKILL_DIR}"
mkdir -p "${AGENT_DIR}"

# Install main seo skill
cp -r "${REPO_DIR}/seo/"* "${SKILL_DIR}/"

# Install each sub-skill
for skill_dir in "${REPO_DIR}/skills"/*/; do
  skill_name=$(basename "${skill_dir}")
  target="${HOME}/.claude/skills/${skill_name}"
  mkdir -p "${target}"
  cp -r "${skill_dir}"* "${target}/"
done

# Install schema templates
if [ -d "${REPO_DIR}/schema" ]; then
  mkdir -p "${SKILL_DIR}/schema"
  cp -r "${REPO_DIR}/schema/"* "${SKILL_DIR}/schema/"
fi

# Install reference PDFs
if [ -d "${REPO_DIR}/pdf" ]; then
  mkdir -p "${SKILL_DIR}/pdf"
  cp -r "${REPO_DIR}/pdf/"* "${SKILL_DIR}/pdf/"
fi

# Install shared scripts
if [ -d "${REPO_DIR}/scripts" ]; then
  mkdir -p "${SKILL_DIR}/scripts"
  cp -r "${REPO_DIR}/scripts/"* "${SKILL_DIR}/scripts/"
fi

# Install subagents
if [ -d "${REPO_DIR}/agents" ]; then
  cp -r "${REPO_DIR}/agents/"*.md "${AGENT_DIR}/" 2>/dev/null || true
fi

# Copy requirements.txt
cp "${REPO_DIR}/requirements.txt" "${SKILL_DIR}/requirements.txt" 2>/dev/null || true

# Install Python dependencies
echo "→ Installing Python dependencies..."
VENV_DIR="${SKILL_DIR}/.venv"
if python3 -m venv "${VENV_DIR}" 2>/dev/null; then
  "${VENV_DIR}/bin/pip" install --quiet -r "${SKILL_DIR}/requirements.txt" 2>/dev/null && \
    echo "  ✓ Installed in venv at ${VENV_DIR}" || \
    echo "  ⚠  Venv pip install failed. Run manually: ${VENV_DIR}/bin/pip install -r ${SKILL_DIR}/requirements.txt"
else
  pip install --quiet --user -r "${SKILL_DIR}/requirements.txt" 2>/dev/null || \
    echo "  ⚠  pip install failed. Run manually: pip install --user -r ${SKILL_DIR}/requirements.txt"
fi

echo "✓ Claude SEO skills installed globally. Use /seo in any project."
