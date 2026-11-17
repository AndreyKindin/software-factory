#!/usr/bin/env bash
# Startet einen Factory-Job: Repo holen, Branch auschecken, Codex mit Playbook laufen lassen.
# Erwartet: REPO, ISSUE, BRANCH, MODEL, WORKFLOW, GH_TOKEN, CODEX_HOME
# und /work/prompt.md (vom Runner geschrieben).
set -euo pipefail

log() { echo "[factory] $*"; }

: "${REPO:?}" "${ISSUE:?}" "${BRANCH:?}"
MODEL="${MODEL:-}"
export PHASE="${PHASE:-build}"   # spec = Entwurf, check = Prüfung, build = Bau, accept = Abnahme
WORKFLOW="${WORKFLOW:-starter-kit}"

# Workflow-Skills als Nutzer-Skills bereitstellen (landen nicht im Ziel-Repo)
mkdir -p "$HOME/.agents/skills"
if [ -d "/factory/workflows/$WORKFLOW/skills" ]; then
  cp -r "/factory/workflows/$WORKFLOW/skills/." "$HOME/.agents/skills/"
fi

if [ "$PHASE" = "spec" ] && [ "${PREPARE_SPEC:-0}" = "1" ]; then
  gh auth setup-git >/dev/null
  gh repo clone "$REPO" /work/repo -- --quiet
  exit 0
fi

if [ "$PHASE" = "spec" ]; then
  cd /work/repo
  SPEC_TEMPLATE=/factory/spec-template.md
  for path in .agents/skills/write-spec/template.md .claude/skills/write-spec/template.md; do
    if [ -f "$path" ]; then
      SPEC_TEMPLATE="$PWD/$path"
      break
    fi
  done
  log "Spec-Vorlage: $SPEC_TEMPLATE"
else
  gh auth setup-git >/dev/null
  GH_LOGIN=$(gh api user --jq .login)
  GH_ID=$(gh api user --jq .id)
  git config --global user.name "$GH_LOGIN (Software Factory)"
  git config --global user.email "${GH_ID}+${GH_LOGIN}@users.noreply.github.com"
  git config --global init.defaultBranch main

  cd /work
  if [ ! -d repo/.git ]; then
    log "Klone $REPO"
    gh repo clone "$REPO" repo -- --quiet
  fi
  cd repo
  git fetch --quiet origin
  DEFAULT_BRANCH=$(gh repo view "$REPO" --json defaultBranchRef --jq .defaultBranchRef.name)
  if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
    git checkout --quiet -B "$BRANCH" "origin/$BRANCH"
    # Die Abnahme startet immer mit genau dem gepushten Stand, ohne Reste früherer Läufe
    if [ "$PHASE" = "accept" ]; then git reset --quiet --hard "origin/$BRANCH" && git clean -ffdxq; fi
  else
    git checkout --quiet -B "$BRANCH" "origin/$DEFAULT_BRANCH"
  fi
  export FACTORY_DEFAULT_BRANCH="$DEFAULT_BRANCH"
fi

# Abhängigkeiten installieren (zum Entwickeln und für die Abnahme nötig)
if { [ "$PHASE" = "build" ] || [ "$PHASE" = "accept" ]; } && [ -f .factory/setup.json ]; then
  INSTALL=$(jq -r '.install // empty' .factory/setup.json)
  if [ -n "$INSTALL" ]; then
    log "Setup: $INSTALL"
    bash -lc "$INSTALL" > /work/setup.log 2>&1 || log "Setup fehlgeschlagen (siehe /work/setup.log), der Agent kümmert sich"
  fi
fi

log "Starte Codex (${MODEL:-CLI-Standard}, Phase: $PHASE, Workflow: $WORKFLOW) für $REPO#$ISSUE auf $BRANCH"
args=()
if [ -n "$MODEL" ]; then args+=(--model "$MODEL"); fi
playbook=$(jq -Rs --arg template "${SPEC_TEMPLATE:-}" '
  if $template == "" then . else
    . + "\n\nFür diesen Spec-Entwurf ist folgende Vorlage verbindlich: `" + $template + "`. Lies sie vollständig und verwende ihre Gliederung."
  end
' /factory/playbook.md)
set +e
factory-codex -a never exec \
  --sandbox danger-full-access --ephemeral --json \
  -c 'features.hooks=false' \
  -c "developer_instructions=$playbook" \
  --output-last-message /work/codex-result.txt \
  "${args[@]}" - < /work/prompt.md > /work/codex.jsonl 2> /work/codex.err
CODE=$?
set -e
log "Codex beendet mit Exit-Code $CODE"
exit "$CODE"
