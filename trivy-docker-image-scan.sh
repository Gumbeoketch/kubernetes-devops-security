#!/bin/bash

dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile) #Getting docker base image name from docker file
echo $dockerImageName

#Running Using Trivy Docker Image
docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.62.1 -q image --exit-code 0 --severity HIGH --light $dockerImageName #Ignore any HIGH (light parameter on trivy to show less details)
docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.62.1 -q image --exit-code 1 --severity CRITICAL --light $dockerImageName #Stop build on CRITICAL

    # Trivy scan result processing
    exit_code=$?
    echo "Exit Code : $exit_code"

    # Check scan results
    if [[ "${exit_code}" == 1 ]]; then
        echo "Image scanning failed. Vulnerabilities found"
        exit 1;
    else
        echo "Image scanning passed. No CRITICAL vulnerabilities found"
    fi;
