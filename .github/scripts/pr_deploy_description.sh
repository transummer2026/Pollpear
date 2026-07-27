#!/usr/bin/env bash
set -euo pipefail

: "${REPO:?}"; : "${PR_NUMBER:?}"; : "${BASE_REF:?}"

git fetch --quiet origin "$BASE_REF"
base="origin/${BASE_REF}"

submodule_rows() {
  git config --file .gitmodules --get-regexp path | while read -r _ path; do
    old=$(git rev-parse "${base}:${path}" 2>/dev/null || true)
    new=$(git rev-parse "HEAD:${path}" 2>/dev/null || true)
    [[ -z "$old" || -z "$new" || "$old" == "$new" ]] && continue
    url=$(git config --file .gitmodules --get "submodule.${path}.url")
    slug=$(printf '%s' "$url" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
    printf '| `%s` | [`%s...%s`](https://github.com/%s/compare/%s...%s) |\n' \
      "$path" "${old:0:8}" "${new:0:8}" "$slug" "$old" "$new"
  done
}

rows=$(submodule_rows)
commits=$(git log --no-merges --pretty=format:'- %s (`%h`)' "${base}..HEAD" || true)

body_file=$(mktemp)
{
  echo "## Deploy dev.pollpear.com"
  echo
  echo "Le merge de cette PR sur \`staging\` déclenche le deploy automatique sur dev.pollpear.com."
  echo
  echo "### Services mis à jour"
  echo
  if [[ -n "$rows" ]]; then
    echo "| Sous-module | Diff |"
    echo "| --- | --- |"
    echo "$rows"
  else
    echo "_Aucun bump de sous-module._"
  fi
  echo
  echo "### Commits (super-repo)"
  echo
  if [[ -n "$commits" ]]; then
    echo "$commits"
  else
    echo "_Aucun commit._"
  fi
  echo
  echo "### Rollback"
  echo "<sub>Description générée automatiquement.</sub>"
} > "$body_file"

gh pr edit "$PR_NUMBER" --repo "$REPO" --body-file "$body_file"
echo "PR #${PR_NUMBER} description updated"
