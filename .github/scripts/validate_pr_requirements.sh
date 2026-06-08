#!/usr/bin/env bash
set -euo pipefail

PR_NUMBER="${PR_NUMBER:?PR_NUMBER is required}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
SKIP_LABEL="${SKIP_LABEL:-no-issue}"
PR_BODY="${PR_BODY:-}"

owner="${GITHUB_REPOSITORY%%/*}"
repo="${GITHUB_REPOSITORY##*/}"

has_skip_label() {
  gh api "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}" \
    --jq ".labels[].name" | grep -qx "${SKIP_LABEL}" || return 1
}

check_linked_reference() {
  local count
  count=$(gh api graphql -f query='
    query($owner: String!, $repo: String!, $pr: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) {
          closingIssuesReferences(first: 20) {
            totalCount
          }
        }
      }
    }
  ' -f owner="$owner" -f repo="$repo" -F pr="$PR_NUMBER" \
    --jq '.data.repository.pullRequest.closingIssuesReferences.totalCount')

  if [[ "$count" -gt 0 ]]; then
    echo "Linked issue reference found."
    return 0
  fi

  if [[ -z "$PR_BODY" ]]; then
    return 1
  fi

  if echo "$PR_BODY" | grep -qE 'github\.com/orgs/fluxerapp/discussions/[0-9]+'; then
    echo "GitHub Discussion URL found in PR body."
    return 0
  fi

  if echo "$PR_BODY" | grep -qE 'github\.com/[^/[:space:]]+/[^/[:space:]]+/discussions/[0-9]+'; then
    echo "GitHub Discussion URL found in PR body."
    return 0
  fi

  if echo "$PR_BODY" | grep -qiE '(close[sd]?|fix(e[sd])?|resolve[sd]?)\s+([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+#[0-9]+|#[0-9]+)'; then
    echo "Issue linking keyword found in PR body."
    return 0
  fi

  return 1
}

check_signed_commits() {
  local commits_json unsigned total
  commits_json=$(gh api "repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/commits" --paginate)

  unsigned=$(echo "$commits_json" | jq -r '
    .[] | select(.commit.verification.verified != true) |
    "\(.sha[0:7]) (\(.commit.verification.reason // "unknown"))"
  ')

  if [[ -n "$unsigned" ]]; then
    echo "::error::The following commits are not verified:"
    while IFS= read -r line; do
      echo "::error::$line"
    done <<< "$unsigned"
    return 1
  fi

  total=$(echo "$commits_json" | jq 'length')
  echo "All ${total} commit(s) are verified."
  return 0
}

if has_skip_label; then
  echo "Label '${SKIP_LABEL}' present — skipping linked issue/discussion check."
else
  if ! check_linked_reference; then
    echo "::error::No linked issue or GitHub Discussion found. Link an issue with a keyword (e.g. Fixes #123) or paste a Discussion URL in the PR body. Maintainers can add the '${SKIP_LABEL}' label to bypass."
    exit 1
  fi
fi

if ! check_signed_commits; then
  exit 1
fi

echo "All PR requirement checks passed."
