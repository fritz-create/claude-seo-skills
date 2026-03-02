#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web (remote/cloud environments)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

# Resolve home directory robustly (HOME may be unset in some web environments)
REAL_HOME="${HOME:-$(eval echo ~)}"
SKILL_DIR="${REAL_HOME}/.claude/skills/seo"
AGENT_DIR="${REAL_HOME}/.claude/agents"

echo "→ Installing Claude SEO skills globally..."

# Create target directories
mkdir -p "${SKILL_DIR}"
mkdir -p "${AGENT_DIR}"

# Install main seo skill
cp -r "${REPO_DIR}/seo/"* "${SKILL_DIR}/"

# Install each sub-skill
for skill_dir in "${REPO_DIR}/skills"/*/; do
  skill_name=$(basename "${skill_dir}")
  target="${REAL_HOME}/.claude/skills/${skill_name}"
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

# ── Bootstrap global hook so skills auto-install in ALL future repos ──────────
GLOBAL_HOOK_DIR="${REAL_HOME}/.claude/hooks"
GLOBAL_HOOK="${GLOBAL_HOOK_DIR}/install-seo-skills.sh"
GLOBAL_SETTINGS="${REAL_HOME}/.claude/settings.json"

# Install the global hook script if not already present
if [ ! -f "${GLOBAL_HOOK}" ]; then
  mkdir -p "${GLOBAL_HOOK_DIR}"
  cp "${REPO_DIR}/.claude/hooks/session-start.sh" "${GLOBAL_HOOK}"
  chmod +x "${GLOBAL_HOOK}"
fi

# Register the global hook in ~/.claude/settings.json if not already present
if [ -f "${GLOBAL_SETTINGS}" ]; then
  if ! grep -q "install-seo-skills" "${GLOBAL_SETTINGS}" 2>/dev/null; then
    # Add SessionStart entry using python3 (avoids jq dependency)
    python3 - <<'PYEOF'
import json, sys, os

settings_path = os.path.expanduser(os.environ.get("GLOBAL_SETTINGS", "~/.claude/settings.json"))
with open(settings_path) as f:
    s = json.load(f)
s.setdefault("hooks", {}).setdefault("SessionStart", [])
hook_entry = {"hooks": [{"type": "command", "command": "~/.claude/hooks/install-seo-skills.sh"}]}
if not any("install-seo-skills" in str(e) for e in s["hooks"]["SessionStart"]):
    s["hooks"]["SessionStart"].append(hook_entry)
with open(settings_path, "w") as f:
    json.dump(s, f, indent=4)
PYEOF
  fi
elif [ ! -f "${GLOBAL_SETTINGS}" ]; then
  cat > "${GLOBAL_SETTINGS}" <<'JSON'
{
    "hooks": {
        "SessionStart": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "~/.claude/hooks/install-seo-skills.sh"
                    }
                ]
            }
        ]
    }
}
JSON
fi
