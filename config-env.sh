#!/bin/bash

# Set variables
JF_URL="https://apptrustinfra.jfrog.io"
JF_USERNAME="talet@jfrog.com"
# read -p "Enter your JFrog username: " JF_USERNAME
read -s -p "Enter your JFrog Access Token: " JF_PASSWORD
echo

# Create BTC Wallet project
# curl -X POST "${JF_URL}/access/api/v1/projects" \
#     -H "Authorization: Bearer ${JF_PASSWORD}" \
#     -H "Content-Type: application/json" \
#     -d '{
#   "display_name": "BTC Wallet",
#   "description": "The BTC Wallet Project",
#   "project_key": "btcwallet"
# }'

# Create Projects Stages (QA, PreProd)
# curl -X POST "${JF_URL}/access/api/v2/stages/" \
#     -H "Authorization: Bearer ${JF_PASSWORD}" \
#     -H "Content-Type: application/json" \
#     -d '{
#   "name": "btcwallet-QA",
#   "scope": "project",
#   "project_key": "btcwallet",
#   "category": "promote",
#   "repositories": []
# }'

# curl -X POST "${JF_URL}/access/api/v2/stages/" \
#     -H "Authorization: Bearer ${JF_PASSWORD}" \
#     -H "Content-Type: application/json" \
#     -d '{
#   "name": "btcwallet-PreProd",
#   "scope": "project",
#   "project_key": "btcwallet",
#   "category": "promote",
#   "repositories": []
# }'

# Create Projects Stages Repos
# Docker local repos
# curl -l -X PUT "${JF_URL}/artifactory/api/v2/repositories/batch" \
#     -H "Content-Type: application/json" \
#     -H "Authorization: Bearer ${JF_PASSWORD}" \
#     -d '
#     [
#     {
#         "key": "btcwallet-dev-docker-local",
#         "projectKey": "btcwallet",
#         "environments": ["DEV"],
#         "packageType": "docker",
#         "xrayIndex": true,
#         "rclass": "local"
#     },
#         {
#         "key": "btcwallet-qa-docker-local",
#         "projectKey": "btcwallet",
#         "environments": ["btcwallet-QA"],
#         "packageType": "docker",
#         "xrayIndex": true,
#         "rclass": "local"
#     },
#     {
#         "key": "btcwallet-preprod-docker-local",
#         "projectKey": "btcwallet",
#         "environments": ["btcwallet-PreProd"],
#         "packageType": "docker",
#         "xrayIndex": true,
#         "rclass": "local"
#     },
#     {
#         "key": "btcwallet-prod-docker-local",
#         "projectKey": "btcwallet",
#         "environments": ["PROD"],
#         "packageType": "docker",
#         "xrayIndex": true,
#         "rclass": "local"
#     }
#     ]'

# Maven local repos
# curl -l -X PUT "${JF_URL}/artifactory/api/v2/repositories/batch" \
#     -H "Content-Type: application/json" \
#     -H "Authorization: Bearer ${JF_PASSWORD}" \
#     -d '
#     [
#     {
#         "key": "btcwallet-dev-maven-local",
#         "projectKey": "btcwallet",
#         "environments": ["DEV"],
#         "packageType": "maven",
#         "xrayIndex": true,
#         "rclass": "local"
#     },
#         {
#         "key": "btcwallet-qa-maven-local",
#         "projectKey": "btcwallet",
#         "environments": ["btcwallet-QA"],
#         "packageType": "maven",
#         "xrayIndex": true,
#         "rclass": "local"
#     },
#     {
#         "key": "btcwallet-preprod-maven-local",
#         "projectKey": "btcwallet",
#         "environments": ["btcwallet-PreProd"],
#         "packageType": "maven",
#         "xrayIndex": true,
#         "rclass": "local"
#     },
#     {
#         "key": "btcwallet-prod-maven-local",
#         "projectKey": "btcwallet",
#         "environments": ["PROD"],
#         "packageType": "maven",
#         "xrayIndex": true,
#         "rclass": "local"
#     }
#     ]'


# Docker remote repo & virtual repo
# curl -l -X PUT "${JF_URL}/artifactory/api/v2/repositories/batch" \
#     -H "Content-Type: application/json" \
#     -H "Authorization: Bearer ${JF_PASSWORD}" \
#     -d '
#     [
#     {
#         "key": "btcwallet-dev-docker-remote",
#         "projectKey": "btcwallet",
#         "environments": ["DEV"],
#         "packageType": "docker",
#         "url": "https://registry-1.docker.io/",
#         "xrayIndex": true,
#         "rclass": "remote"
#     }
#     ]'

# curl -l -X PUT "${JF_URL}/artifactory/api/v2/repositories/batch" \
#     -H "Content-Type: application/json" \
#     -H "Authorization: Bearer ${JF_PASSWORD}" \
#     -d '
#     [
#         {
#         "key": "btcwallet-dev-docker-virtual",
#         "projectKey": "btcwallet",
#         "environments": ["DEV"],
#         "repositories": ["btcwallet-dev-docker-local", "btcwallet-dev-docker-remote"],
#         "packageType": "docker",
#         "rclass": "virtual"
#     }
#     ]'

# Maven remote & virtual repos
# curl -l -X PUT "${JF_URL}/artifactory/api/v2/repositories/batch" \
#     -H "Content-Type: application/json" \
#     -H "Authorization: Bearer ${JF_PASSWORD}" \
#     -d '
#     [
#     {
#         "key": "btcwallet-dev-maven-remote",
#         "projectKey": "btcwallet",
#         "environments": ["DEV"],
#         "packageType": "maven",
#         "url": "https://repo.maven.apache.org/maven2/",
#         "xrayIndex": true,
#         "rclass": "remote"
#     }
#     ]'

# curl -l -X PUT "${JF_URL}/artifactory/api/v2/repositories/batch" \
#     -H "Content-Type: application/json" \
#     -H "Authorization: Bearer ${JF_PASSWORD}" \
#     -d '
#     [
#         {
#         "key": "btcwallet-dev-maven-virtual",
#         "projectKey": "btcwallet",
#         "environments": ["DEV"],
#         "repositories": ["btcwallet-dev-maven-local", "btcwallet-dev-maven-remote"],
#         "packageType": "maven",
#         "rclass": "virtual"
#     }
#     ]'

# TODO:
## Automate Lifecycle edit to add stages

# Create new application
curl -X POST "${JF_URL}/apptrust/api/v1/applications" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${JF_PASSWORD}" \
    -d '
        {
    "application_name": "BTC Wallet App",
    "application_key": "btcwalletapp",
    "project_key": "btcwallet",
    "description": "This application contains the BTC Wallet services.",
    "maturity_level": "production",
    "criticality": "high",
    "labels": {
        "environment": "production",
        "region": "us-east"
    }
    }'