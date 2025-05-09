#!/bin/bash
set -euo pipefail

echo 'Testing Development Image'

IMAGE="$(
    < components/tkn-go-github-test-4/overlays/development/deployment-patch.yaml \
    yq '.spec.template.spec.containers[0].image'
)"
echo "Image: ${IMAGE}"

DIGEST="${IMAGE#*@}"
echo "Digest: ${DIGEST}"

GIT_URL="$(git remote get-url origin | sed 's_git@github\.com:_https://github.com/_')"
GIT_URL="${GIT_URL%.git}"
echo "Git URL: ${GIT_URL}"

GIT_COMMIT="$(git rev-parse HEAD)"
echo "Git commit ID: ${GIT_COMMIT}"

TEST_FILE='hack/test-development-image.sh'
echo "Test file: ${TEST_FILE}"

# TODO: Perform some tests here

# https://github.com/in-toto/attestation/blob/main/spec/predicates/test-result.md
cat >> predicate.json <<EOF
{
    "result": "PASSED",
    "configuration": [{
        "name": "hack/test-development-image.sh",
        "downloadLocation": "${GIT_URL}/blob/${GIT_COMMIT}/${TEST_FILE}",
        "digest": {
            "gitBlob": "${GIT_COMMIT}"
        }
    }],
    "passedTests": [
        "test 01",
        "test 02"
    ],
    "warnedTests": [],
    "failedTests": []
}
EOF

echo "Predicate:"
cat predicate.json

SIGNING_DIR="${1-}"
if [[ ! -n "$SIGNING_DIR" ]]; then
    echo "Signing directory not provided. Skipping attestation."
    exit 0
fi

COSIGN_PASSWORD_FILE="${SIGNING_DIR}/cosign.password"
COSIGN_PRIVATE_KEY_FILE="${SIGNING_DIR}/cosign.key"
COSIGN_PUBLIC_KEY_FILE="${SIGNING_DIR}/cosign.pub"
if [[ ! -f "$COSIGN_PASSWORD_FILE" || ! -f "$COSIGN_PRIVATE_KEY_FILE" ]]; then
    echo "$COSIGN_PASSWORD_FILE and $COSIGN_PRIVATE_KEY_FILE must both be provided. Skipping attestation."
    exit 0
fi
COSIGN_PASSWORD="$(cat ${COSIGN_PASSWORD_FILE})"

# Needed for the `cosign attest` command.
export COSIGN_PASSWORD

# TODO: Also add support for custom Rekor instance?

cosign attest --predicate predicate.json \
    --type 'https://in-toto.io/attestation/test-result/v0.1' \
    --key "${COSIGN_PRIVATE_KEY_FILE}" \
    --yes \
    "${IMAGE}"
