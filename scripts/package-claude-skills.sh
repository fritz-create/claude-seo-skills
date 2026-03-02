#!/usr/bin/env bash
# package-claude-skills.sh
# Packages all SEO skills as ZIP files ready to upload to claude.ai
# Usage: bash scripts/package-claude-skills.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${REPO_DIR}/dist/claude-skills"

echo "════════════════════════════════════════"
echo "║  Claude SEO → claude.ai Skills       ║"
echo "════════════════════════════════════════"
echo ""

command -v zip >/dev/null 2>&1 || { echo "✗ 'zip' is required. Install with: apt-get install zip"; exit 1; }

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

package_skill() {
  local skill_name="$1"
  local skill_src="$2"
  local zip_path="${DIST_DIR}/${skill_name}.zip"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  # Copy skill folder into tmp dir preserving the folder name
  cp -r "${skill_src}" "${tmp_dir}/${skill_name}"

  (cd "${tmp_dir}" && zip -r "${zip_path}" "${skill_name}" -x "*.venv*" -x "*.pyc" -x "__pycache__/*" -q)
  rm -rf "${tmp_dir}"

  echo "  ✓ ${skill_name}.zip"
}

# Package main seo skill (includes references/ subfolder)
echo "→ Packaging skills..."
package_skill "seo" "${REPO_DIR}/seo"

# Package each sub-skill
for skill_dir in "${REPO_DIR}/skills"/*/; do
  skill_name=$(basename "${skill_dir}")
  package_skill "${skill_name}" "${skill_dir}"
done

echo ""
echo "✓ ${DIST_DIR}/"
ls "${DIST_DIR}"/*.zip | while read -r f; do printf "    %s\n" "$(basename "$f")"; done

echo ""
echo "Next steps — upload to claude.ai:"
echo "  1. Go to claude.ai → Settings → Customize → Skills"
echo "  2. Click '+' and upload each .zip from: dist/claude-skills/"
echo "  3. Start with 'seo.zip' (the main orchestrator)"
echo ""
echo "Tip: upload 'seo.zip' first — it handles all /seo sub-commands."
echo "     Upload sub-skill ZIPs only if you want them as standalone skills."
