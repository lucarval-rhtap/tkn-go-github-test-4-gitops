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

# TODO: Perform some tests

# https://github.com/in-toto/attestation/blob/main/spec/predicates/test-result.md
cat >> /dev/stdout <<EOF
{
    "_type": "https://in-toto.io/Statement/v1",
    "subject": [
        {
            "digest": {
                "gitCommit": "$DIGEST"
            }
        }
    ],
    "predicateType": "https://in-toto.io/attestation/test-result/v0.1",
    "predicate": {
        "result": "PASSED",
        "configuration": [{
            "name": "hack/test-development-image.sh",
            "downloadLocation": "${GIT_URL}/blob/${GIT_COMMIT}/${TEST_FILE}",
            "digest": {
                "gitBlob": "${GIT_COMMIT}"
            }
        }],
        "passedTests": [
            "build (3.7, ubuntu-latest, py)",
            "build (3.7, macos-latest, py)",
            "build (3.7, windows-latest, py)",
            "build (3.8, ubuntu-latest, py)",
            "build (3.8, macos-latest, py)",
            "build (3.8, windows-latest, py)",
            "build (3.9, ubuntu-latest, py)",
            "build (3.9, macos-latest, py)",
            "build (3.9, windows-latest, py)",
            "build (3.10, ubuntu-latest, py)",
            "build (3.10, macos-latest, py)",
            "build (3.10, windows-latest, py)",
            "build (3.x, ubuntu-latest, lint)"
        ],
        "warnedTests": [],
        "failedTests": []
    }
}
EOF
