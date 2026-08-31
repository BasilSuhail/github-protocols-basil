#!/usr/bin/env bash
# Personal identifier screen — EXAMPLE ONLY.
#
# Copy to ~/.agents/lib/personal-identifiers.sh and put your real terms there.
# That destination is untracked and is never pushed anywhere.
#
#   cp lib/personal-identifiers.example.sh ~/.agents/lib/personal-identifiers.sh
#
# Do NOT fill in real names, institutions, emails, or phone numbers in THIS
# file. It is tracked and public. A blocklist committed to a public repo
# publishes exactly the strings it exists to suppress — the leak it was built
# to prevent, in machine-readable form.
#
# lib/rules.sh (ID-401) sources whichever copy it finds and calls screen_files.

# Names of people and institutions. Third-party names matter most: they did
# not choose to appear in your repository.
PERSONAL_HARD='(Firstname[[:space:]]+Lastname|Some[[:space:]]+University|CODE[0-9]{4})'

# Framing that reveals what the work is for and who assesses it.
ACADEMIC_HARD='(\bviva\b|\bdissertation\b|\bMSc\b|supervisor|examiner|\bthesis\b)'

# Legitimate elsewhere, suspicious here. Warns, never blocks. Keep this list
# narrow: a warning that fires on ordinary words trains you to ignore all of
# them, which is worse than having no warning.
ACADEMIC_SOFT='(\bcoursework\b|\bmarking scheme\b|\bword count\b)'

# Personal contact details and private network addresses.
CONTACT_HARD='([a-zA-Z0-9._%+-]+@(gmail|outlook|hotmail|yahoo|icloud)\.[a-z.]+|\+[0-9]{1,3}[[:space:]]?[0-9]{9,})'

# Skip binaries, lockfiles and vendored data. A city name in a gazetteer is
# not a disclosure.
_screen_skip() {
  case "$1" in
    *.lock|*lock.json|*lock.yaml|*.min.js|*.map|*.png|*.jpg|*.jpeg|*.gif|*.pdf|*.zip|*.woff*) return 0 ;;
    */node_modules/*|*/vendor/*|*.ipynb) return 0 ;;
  esac
  return 1
}

# screen_files <file>...  -> 0 clean, 1 blocked
screen_files() {
  local blocked=0 warned=0 f hits

  for f in "$@"; do
    [ -f "$f" ] || continue
    _screen_skip "$f" && continue

    for pair in "PERSONAL_HARD:personal or institutional identifier" \
                "ACADEMIC_HARD:assessment or degree framing" \
                "CONTACT_HARD:personal contact detail"; do
      var="${pair%%:*}"; label="${pair##*:}"
      hits=$(grep -nEi "${!var}" "$f" 2>/dev/null | head -3 || true)
      if [ -n "$hits" ]; then
        echo "BLOCKED  $f — $label"
        echo "$hits" | sed 's/^/         /'
        blocked=1
      fi
    done

    hits=$(grep -nEi "$ACADEMIC_SOFT" "$f" 2>/dev/null | head -2 || true)
    if [ -n "$hits" ]; then
      echo "WARN     $f — confirm this belongs in a public repository"
      echo "$hits" | sed 's/^/         /'
      warned=1
    fi
  done

  if [ "$blocked" = "1" ]; then
    echo
    echo "Anything pushed to a public repository is copied beyond your control"
    echo "the moment it lands. Deleting it later does not reach the copies."
    echo
    echo "Write the role, not the person: reviewer, operator, maintainer."
    echo "Write the work, not the assessment: project, report, review."
    echo
    echo "Waive once, from your own shell:  PROTOCOL_OVERRIDE=ID-401 git commit ..."
    return 1
  fi
  [ "$warned" = "1" ] && echo
  return 0
}
