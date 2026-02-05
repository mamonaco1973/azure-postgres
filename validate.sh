#!/bin/bash
# ===============================================================================
# FILE: validate.sh
# ===============================================================================
# Resolves and prints the pgweb endpoint and the PostgreSQL Flexible Server
# endpoint. Also waits for pgweb to become reachable before returning success.
#
# OUTPUT (SUMMARY):
#   - pgweb URL
#   - PostgreSQL Flexible Server hostname
# ===============================================================================

# Enable strict shell behavior:
#   -e  Exit immediately on error
#   -u  Treat unset variables as errors
#   -o pipefail  Fail pipelines if any command fails
set -euo pipefail


# ===============================================================================
# CONFIGURATION
# ===============================================================================
RESOURCE_GROUP_NAME="postgres-rg"
PGWEB_PUBLIC_IP_NAME="pgweb-vm-public-ip"
PGWEB_PATH="/"
POSTGRES_NAME_PREFIX="postgres-instance"

MAX_ATTEMPTS=30
SLEEP_SECONDS=30


# ===============================================================================
# RESOLVE PGWEB PUBLIC DNS
# ===============================================================================
PGWEB_FQDN="$(az network public-ip show \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${PGWEB_PUBLIC_IP_NAME}" \
  --query "dnsSettings.fqdn" \
  --output tsv)"

if [ -z "${PGWEB_FQDN}" ] || [ "${PGWEB_FQDN}" = "None" ]; then
  echo "ERROR: Could not resolve pgweb public FQDN."
  echo "ERROR: Ensure Public IP '${PGWEB_PUBLIC_IP_NAME}' exists."
  exit 1
fi

PGWEB_URL="http://${PGWEB_FQDN}${PGWEB_PATH}"


# ===============================================================================
# WAIT FOR PGWEB TO BECOME REACHABLE
# ===============================================================================
echo "NOTE: Waiting for pgweb to become available:"
echo "NOTE:   ${PGWEB_URL}"

attempt=1
until curl -sS "${PGWEB_URL}" >/dev/null 2>&1; do
  if [ "${attempt}" -ge "${MAX_ATTEMPTS}" ]; then
    echo "ERROR: pgweb did not become available after ${MAX_ATTEMPTS} attempts."
    echo "ERROR: Last checked URL: ${PGWEB_URL}"
    exit 1
  fi

  echo "NOTE: pgweb not reachable yet. Retry ${attempt}/${MAX_ATTEMPTS}."
  sleep "${SLEEP_SECONDS}"
  attempt=$((attempt + 1))
done


# ===============================================================================
# RESOLVE POSTGRES FLEXIBLE SERVER ENDPOINT
# ===============================================================================
POSTGRES_FQDN="$(az postgres flexible-server list \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --query "[?starts_with(name, '${POSTGRES_NAME_PREFIX}')].fullyQualifiedDomainName" \
  --output tsv)"

if [ -z "${POSTGRES_FQDN}" ] || [ "${POSTGRES_FQDN}" = "None" ]; then
  echo "ERROR: Could not resolve PostgreSQL Flexible Server endpoint."
  echo "ERROR: No server found with prefix '${POSTGRES_NAME_PREFIX}'."
  exit 1
fi


# ===============================================================================
# OUTPUT SUMMARY
# ===============================================================================
echo "==============================================================================="
echo "BUILD VALIDATION RESULTS"
echo "==============================================================================="
echo "pgweb URL:"
echo "  ${PGWEB_URL}"
echo
echo "PostgreSQL Flexible Server Endpoint:"
echo "  ${POSTGRES_FQDN}"
echo "==============================================================================="
