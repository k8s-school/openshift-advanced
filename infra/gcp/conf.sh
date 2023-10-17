PROJECT_ID="openshift-399509"

# DNS
NAME="openshift"
ZONE="cluster.k8s-school.fr"

# Service account
SA_NAME="openshift"
DESCRIPTION="openshift"
DISPLAY_NAME="openshift"
SA_ID="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
SA_KEY="$HOME/.gcp/osServiceAccount.json"

# Openshift install
INSTALL_DIR="/data/openshift-install"