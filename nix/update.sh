#!/usr/bin/env bash
# Single Responsibility: Detect outdated Nix profile packages and upgrade only those
set -euo pipefail

CHANNEL="${NIX_UPDATE_CHANNEL:-nixpkgs-unstable}"
CACHE_DIR="${NIX_UPDATE_CACHE:-/tmp/nix-update}"
CACHE_TTL="${NIX_UPDATE_TTL:-3600}"

locate_nix() {
    if [ -x "$HOME/.nix-profile/bin/nix" ]; then
        echo "$HOME/.nix-profile/bin/nix"
        return 0
    fi
    if [ -x "/nix/var/nix/profiles/default/bin/nix" ]; then
        echo "/nix/var/nix/profiles/default/bin/nix"
        return 0
    fi
    if command -v nix >/dev/null 2>&1; then
        command -v nix
        return 0
    fi
    return 1
}

show_help() {
    cat << HELP
Usage: ./update.sh [OPTIONS] [PACKAGES...]

Fetch the latest package versions with curl, compare them against your Nix
profile and run 'nix profile upgrade' on the outdated entries only.
GitHub flakes pinned to a version tag (github:owner/repo/v1.2.3) are
reinstalled on the newest release tag. packages.txt is synced afterwards.

Options:
  -n, --dry-run     Show what would be upgraded, change nothing
  -r, --refresh     Ignore the cache and fetch everything again
  -h, --help        Show this help message

Arguments:
  PACKAGES          Limit the check to these profile entry names

Cache:
  Fetched data lives in $CACHE_DIR and is reused for ${CACHE_TTL}s.
  Environment: NIX_UPDATE_CACHE, NIX_UPDATE_TTL, NIX_UPDATE_CHANNEL

Examples:
  ./update.sh --dry-run             # List outdated packages
  ./update.sh                       # Upgrade every outdated package
  ./update.sh gh zed-editor         # Upgrade only these if outdated
HELP
}

# True when the file exists and is younger than CACHE_TTL
is_fresh() {
    local file="$1"
    if [ "${REFRESH:-0}" = "1" ] || [ ! -s "$file" ]; then
        return 1
    fi
    local age=$(( $(date +%s) - $(stat -c %Y "$file") ))
    [ "$age" -lt "$CACHE_TTL" ]
}

decompress_brotli() {
    if command -v brotli >/dev/null 2>&1; then
        brotli -d -c
        return 0
    fi
    "$NIX_BIN" run nixpkgs#brotli -- -d -c
}

# Prints the latest channel revision, cached
fetch_channel_revision() {
    local rev_file="$CACHE_DIR/$CHANNEL.revision"
    if ! is_fresh "$rev_file"; then
        echo "Fetching $CHANNEL revision..." >&2
        curl -sfL "https://channels.nixos.org/$CHANNEL/git-revision" -o "$rev_file.tmp"
        mv "$rev_file.tmp" "$rev_file"
    fi
    cat "$rev_file"
}

# Prints the path of an "attr<TAB>name<TAB>version" index for the revision, cached
fetch_package_index() {
    local rev="$1"
    local index_file="$CACHE_DIR/$CHANNEL-${rev:0:12}.tsv"
    if [ -s "$index_file" ] && [ "${REFRESH:-0}" != "1" ]; then
        echo "$index_file"
        return 0
    fi
    echo "Fetching $CHANNEL package index (${rev:0:12}, ~10MB)..." >&2
    curl -sfL "https://channels.nixos.org/$CHANNEL/packages.json.br" \
        | decompress_brotli \
        | jq -r '.packages | to_entries[] | "\(.key)\t\(.value.name)\t\(.value.version)"' \
        > "$index_file.tmp"
    mv "$index_file.tmp" "$index_file"
    echo "$index_file"
}

# Prints the commit sha a github ref points to, cached
fetch_github_sha() {
    local repo="$1"
    local ref="$2"
    local sha_file="$CACHE_DIR/github-${repo//\//_}-${ref:-HEAD}.sha"
    if ! is_fresh "$sha_file"; then
        curl -sfL -H "Accept: application/vnd.github.sha" \
            "https://api.github.com/repos/$repo/commits/${ref:-HEAD}" -o "$sha_file.tmp" || return 1
        mv "$sha_file.tmp" "$sha_file"
    fi
    cat "$sha_file"
}

# Prints the newest release tag of a github repo (latest tag as fallback), cached
fetch_github_latest_tag() {
    local repo="$1"
    local tag_file="$CACHE_DIR/github-${repo//\//_}.latest-tag"
    if ! is_fresh "$tag_file"; then
        local tag
        tag="$(curl -sfL "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name // empty')" || tag=""
        if [ -z "$tag" ]; then
            tag="$(curl -sfL "https://api.github.com/repos/$repo/tags?per_page=1" | jq -r '.[0].name // empty')" || return 1
        fi
        [ -n "$tag" ] || return 1
        echo "$tag" > "$tag_file"
    fi
    cat "$tag_file"
}

# Prints "name<TAB>origin<TAB>locked-url<TAB>attr<TAB>store-names" per profile entry
list_profile() {
    "$NIX_BIN" profile list --json | jq -r '
        .elements | to_entries[] | [
            .key,
            (.value.originalUrl // ""),
            (.value.url // ""),
            ((.value.attrPath // "") | sub("^(legacyPackages|packages)\\.[^.]+\\."; "")),
            ((.value.storePaths // []) | map(.[44:]) | join(","))
        ] | @tsv'
}

# True when one of the installed store names carries the latest name or version
is_current() {
    local store_names="$1"
    local latest_name="$2"
    local latest_version="$3"
    local store_name
    IFS=',' read -ra names <<< "$store_names"
    for store_name in "${names[@]}"; do
        case "$store_name" in
            "$latest_name"|"$latest_name"-*|*-"$latest_version"|*-"$latest_version"-*)
                return 0
                ;;
        esac
    done
    return 1
}

# Prints "name<TAB>installed<TAB>latest<TAB>new-flake-ref" for every outdated entry.
# new-flake-ref is set when the entry is pinned to a version tag and must be reinstalled.
find_outdated() {
    local index_file="$1"
    shift
    local wanted=" $* "

    local name origin locked attr store_names
    while IFS=$'\t' read -r name origin locked attr store_names; do
        if [ "$wanted" != "  " ] && [[ "$wanted" != *" $name "* ]]; then
            continue
        fi

        if [ "$origin" = "flake:nixpkgs" ]; then
            local latest
            latest="$(awk -F'\t' -v a="$attr" '$1 == a { print $2 "\t" $3; exit }' "$index_file")"
            if [ -z "$latest" ]; then
                echo "  ? $name: not in $CHANNEL index, skipped" >&2
                continue
            fi
            local latest_name="${latest%%$'\t'*}"
            local latest_version="${latest#*$'\t'}"
            if ! is_current "$store_names" "$latest_name" "$latest_version"; then
                printf '%s\t%s\t%s\n' "$name" "${store_names%%,*}" "$latest_name"
            fi
            continue
        fi

        if [[ "$origin" == github:* ]]; then
            local path="${origin#github:}"
            path="${path%%\?*}"
            local repo ref=""
            repo="$(cut -d/ -f1-2 <<< "$path")"
            if [ "$(tr -cd / <<< "$path" | wc -c)" -ge 2 ]; then
                ref="${path#*/*/}"
            fi

            # A version tag never moves: look for a newer release instead
            if [[ "$ref" =~ ^v?[0-9] ]]; then
                local latest_tag
                latest_tag="$(fetch_github_latest_tag "$repo")" || {
                    echo "  ? $name: github release lookup failed, skipped" >&2
                    continue
                }
                if [ "$latest_tag" != "$ref" ]; then
                    printf '%s\t%s\t%s\t%s\n' "$name" "$ref" "$latest_tag" "github:$repo/$latest_tag#$attr"
                fi
                continue
            fi

            local locked_sha="${locked#github:"$repo"/}"
            locked_sha="${locked_sha%%\?*}"
            local latest_sha
            latest_sha="$(fetch_github_sha "$repo" "$ref")" || {
                echo "  ? $name: github lookup failed, skipped" >&2
                continue
            }
            if [ "$locked_sha" != "$latest_sha" ]; then
                printf '%s\t%s\t%s\n' "$name" "${locked_sha:0:12}" "${latest_sha:0:12}"
            fi
            continue
        fi

        echo "  ? $name: unsupported origin '$origin', skipped" >&2
    done < <(list_profile)
}

main() {
    local dry_run=0
    local only=()
    REFRESH=0

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--dry-run)
                dry_run=1
                shift
                ;;
            -r|--refresh)
                REFRESH=1
                shift
                ;;
            -*)
                echo "Error: unknown option '$1'." >&2
                exit 1
                ;;
            *)
                only+=("$1")
                shift
                ;;
        esac
    done

    NIX_BIN="$(locate_nix)" || {
        echo "Error: nix binary not found." >&2
        exit 1
    }
    command -v jq >/dev/null 2>&1 || {
        echo "Error: jq is required." >&2
        exit 1
    }
    mkdir -p "$CACHE_DIR"

    local rev index_file
    rev="$(fetch_channel_revision)"
    index_file="$(fetch_package_index "$rev")"

    local outdated
    outdated="$(find_outdated "$index_file" "${only[@]}")"

    if [ -z "$outdated" ]; then
        echo "Everything is up to date."
        exit 0
    fi

    echo ""
    echo "Outdated packages:"
    awk -F'\t' '{ printf "  %-28s %s -> %s\n", $1, $2, $3 }' <<< "$outdated"
    echo ""

    if [ "$dry_run" = "1" ]; then
        echo "Dry run: nothing upgraded."
        exit 0
    fi

    mapfile -t pkgs < <(awk -F'\t' '$4 == "" { print $1 }' <<< "$outdated")
    if [ ${#pkgs[@]} -gt 0 ]; then
        echo "Upgrading ${#pkgs[@]} package(s) via Nix profile..."
        "$NIX_BIN" profile upgrade --impure "${pkgs[@]}"
    fi

    local name new_ref failed=0
    while IFS=$'\t' read -r name _ _ new_ref; do
        reinstall_package "$name" "$new_ref" || failed=1
    done < <(awk -F'\t' '$4 != ""' <<< "$outdated")

    echo ""
    "$(dirname "$0")/sync.sh"
    exit "$failed"
}

# Swaps a tag-pinned entry for a newer tag; rolls back the removal if the add fails
reinstall_package() {
    local name="$1"
    local new_ref="$2"
    echo "Reinstalling $name from $new_ref..."
    "$NIX_BIN" profile remove "$name"
    if ! "$NIX_BIN" profile add --impure "$new_ref"; then
        echo "Error: failed to add $new_ref, rolling back." >&2
        "$NIX_BIN" profile rollback
        return 1
    fi
}

main "$@"
