#!/bin/bash
# vault-sync — commit a sensitive repo locally, then replace ONE encrypted
# archive of it in Dropbox.
#
# For repos that must never get a git remote. lawyer-tool-rs is the case this was
# built for: its history carries real client agreements, so pushing it anywhere
# would publish third-party confidential documents irreversibly. But "no remote"
# had meant "no backup at all", which is the same disaster from the other side.
#
# WHY ONE FILE, NOT A SYNCED FOLDER. Dropbox chokes on many small files changing
# constantly — .git's thousands of loose objects, every intermediate save — and
# produces conflicted copies mid-write. It handles one file that changes
# atomically perfectly. So git stays local and Dropbox gets a single archive:
# ~31 MB for lawyer-tool-rs, because build output is excluded and it is 99% of
# the repo (3.0 GB of a 3.1 GB tree).
#
# WHY ENCRYPTED. Third-party confidential agreements are going into consumer
# cloud storage. The passphrase lives in the login Keychain so this can run
# unattended.
#
#   *** IF THIS MAC DIES, THE KEYCHAIN DIES WITH IT. ***
#   The passphrase is printed ONCE when first generated. Put it in your password
#   manager immediately. Without it the Dropbox archive is undecryptable — a
#   backup that fails in exactly the disaster it exists for.
#
# Usage:
#   vault-sync.sh <repo-path> [-m "commit message"]
#   vault-sync.sh <repo-path> --verify-only     check the existing archive
#
# Restore (the whole point — keep this readable):
#   gpg --decrypt vault-<name>.tar.gz.gpg | tar xz
set -uo pipefail

VAULT_DIR="${VAULT_DIR:-$HOME/Dropbox/* Vault}"
KEYCHAIN_SERVICE="vault-sync"
KEYCHAIN_ACCOUNT="archive-passphrase"
EXCLUDES=(target node_modules .venv build .DS_Store)

die() { printf 'vault-sync: %s\n' "$*" >&2; exit 1; }
say() { printf 'vault-sync: %s\n' "$*"; }

command -v gpg >/dev/null 2>&1 || die "gpg not found — install it (brew install gnupg)"

# ── passphrase ───────────────────────────────────────────────────────────────
# Read from the login Keychain; generate and store on first run. Generating
# rather than prompting means the passphrase is strong and this can be scheduled,
# but it MUST be recorded off-machine, so a fresh one is printed loudly once.
get_passphrase() {
  local p
  p=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w 2>/dev/null)
  if [ -n "$p" ]; then printf '%s' "$p"; return 0; fi

  p=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 40)
  if ! security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w "$p" -U 2>/dev/null; then
    die "could not store the passphrase in the Keychain — refusing to encrypt with a secret that is not saved anywhere"
  fi
  cat >&2 <<EOF

  ══════════════════════════════════════════════════════════════════════
   A NEW VAULT PASSPHRASE WAS GENERATED AND STORED IN YOUR LOGIN KEYCHAIN
   (service "$KEYCHAIN_SERVICE", account "$KEYCHAIN_ACCOUNT")

     $p

   PUT THIS IN YOUR PASSWORD MANAGER NOW.

   It is printed exactly once. The Keychain lives on this Mac only, so if
   this machine is lost the archive in Dropbox becomes undecryptable —
   which is precisely the situation the archive exists for.
  ══════════════════════════════════════════════════════════════════════

EOF
  printf '%s' "$p"
}

# ── args ─────────────────────────────────────────────────────────────────────
REPO=""; MSG=""; VERIFY_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    -m|--message) MSG="${2:-}"; shift 2 ;;
    --verify-only) VERIFY_ONLY=1; shift ;;
    -*) die "unknown flag $1" ;;
    *) REPO="$1"; shift ;;
  esac
done
[ -n "$REPO" ] || die "usage: vault-sync.sh <repo-path> [-m \"message\"]"
REPO="$(cd "$REPO" 2>/dev/null && pwd)" || die "no such directory"
git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$REPO is not a git worktree"

NAME="$(basename "$REPO")"
ARCHIVE="$VAULT_DIR/vault-$NAME.tar.gz.gpg"
mkdir -p "$VAULT_DIR" || die "cannot create $VAULT_DIR"

# ── verify-only ──────────────────────────────────────────────────────────────
# A backup nobody has ever read is not known to be a backup. This proves the
# archive decrypts AND that tar can walk it, rather than trusting that it wrote.
verify_archive() {
  local pass="$1"
  [ -f "$ARCHIVE" ] || { say "no archive at $ARCHIVE"; return 1; }
  local n
  n=$(gpg --batch --quiet --yes --passphrase "$pass" --decrypt "$ARCHIVE" 2>/dev/null | tar tz 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -lt 1 ]; then
    say "VERIFY FAILED — the archive did not decrypt to a readable tar"
    return 1
  fi
  say "verified: $ARCHIVE decrypts and lists $n entries ($(du -h "$ARCHIVE" | cut -f1))"
  return 0
}

PASS="$(get_passphrase)"
[ -n "$PASS" ] || die "no passphrase available"

if [ "$VERIFY_ONLY" = "1" ]; then
  verify_archive "$PASS"; exit $?
fi

# ── commit half ──────────────────────────────────────────────────────────────
# The local commit is the version history; the archive is the off-machine copy.
# Both, every time, so they can never describe different states.
#
# `git add -u`, NEVER `git add -A`. This runs on repos whose working directory
# holds files that are deliberately untracked — in lawyer-tool-rs, real client
# agreements. `-A` would sweep those into git history, which is permanent, and
# would be this script causing the exact harm it was written to avoid.
#
# They are still backed up: the tar below archives the whole tree, tracked or
# not. Which is the right split — the archive is private and replaceable, git
# history is forever.
if [ -n "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]; then
  git -C "$REPO" add -u || die "git add failed"
  msg="${MSG:-vault: checkpoint $(date '+%Y-%m-%d %H:%M')}"
  if git -C "$REPO" commit -q -m "$msg"; then
    say "committed: $msg"
  else
    die "commit failed (a pre-commit hook may have refused it) — NOT archiving a state that would not commit"
  fi
else
  say "working tree clean — nothing to commit"
fi

# ── archive half ─────────────────────────────────────────────────────────────
TMP="$(mktemp -d)" || die "mktemp failed"
trap 'rm -rf "$TMP"' EXIT

TAR_EXCLUDES=()
for e in "${EXCLUDES[@]}"; do TAR_EXCLUDES+=(--exclude="$e"); done

# Archive the WHOLE tree including .git, so a restore brings back full history
# and every untracked working file. Build output is excluded because it is
# regenerable and 99% of the bytes.
if ! tar czf "$TMP/payload.tar.gz" "${TAR_EXCLUDES[@]}" -C "$(dirname "$REPO")" "$NAME" 2>/dev/null; then
  die "tar failed — nothing was written to the vault"
fi

if ! gpg --batch --quiet --yes --symmetric --cipher-algo AES256 \
      --passphrase "$PASS" -o "$TMP/payload.gpg" "$TMP/payload.tar.gz"; then
  die "encryption failed — nothing was written to the vault"
fi

# Atomic replace: write beside the target then mv, so Dropbox never sees a
# half-written archive and there is no window with no backup at all.
mv -f "$TMP/payload.gpg" "$ARCHIVE" || die "could not place the archive at $ARCHIVE"
say "wrote $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"

verify_archive "$PASS" || die "the archive was written but did NOT verify — treat it as no backup"
say "done — git history is local, one encrypted file is in Dropbox"
