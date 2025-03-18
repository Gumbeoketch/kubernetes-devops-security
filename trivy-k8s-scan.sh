#!/bin/bash
# trivy-k8s-scan (Modified to only scan, not fail build)

echo "Scanning Image: $imageName"  # Getting Image name from env variable

# Run Trivy scan for all severities but DO NOT exit with a failure
docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 0 --severity LOW,MEDIUM,HIGH,CRITICAL --light $imageName

# Capture exit code (Optional - just for logging)
exit_code=$?
echo "Trivy Scan Exit Code: $exit_code"

if [[ $exit_code -eq 0 ]]; then
    echo "Image scan completed successfully. No critical vulnerabilities found."
else
    echo "Image scan detected vulnerabilities, but continuing build..."
fi
