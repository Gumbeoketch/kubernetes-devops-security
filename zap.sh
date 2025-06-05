#!/bin/bash

# ==== USER INPUTS OR ENV VARS (set these) ====
serviceName="devsecops-svc"
applicationURL="http://13.246.61.247"

# ==== Extract NodePort safely ====
PORT=$(kubectl -n default get svc ${serviceName} -o json | jq '.spec.ports[] | select(.port==8080) | .nodePort')

if [[ -z "$PORT" ]]; then
  echo "Failed to get NodePort. Exiting."
  exit 1
fi

echo "Scanning target: $applicationURL:$PORT"

# ==== File permissions ====
chmod 777 $(pwd)

# ==== Run ZAP scan ====
docker pull ghcr.io/zaproxy/zaproxy:weekly

docker run --rm -v $(pwd):/zap/wrk/:rw \
  -t ghcr.io/zaproxy/zaproxy:weekly \
  zap-api-scan.py -t "$applicationURL:$PORT/v3/api-docs" \
  -f openapi -c zap_rules -r zap_report.html

exit_code=$?

# ==== Move report if generated ====
if [[ -f zap_report.html ]]; then
  mkdir -p owasp-zap-report
  mv zap_report.html owasp-zap-report/
else
  echo "ZAP report not found!"
  exit 1
fi

# ==== Handle exit code ====
echo "Exit Code : $exit_code"

if [[ ${exit_code} -ne 0 ]]; then
  echo "OWASP ZAP reported risks. Check the report."
  exit 1
else
  echo "OWASP ZAP did not report any Risk."
fi
