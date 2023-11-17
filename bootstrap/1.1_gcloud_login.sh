#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/env.sh

cat <<EOF > /tmp/gcloud-login.sh
#!/bin/bash

set -x

sh -c "\$(k8s-toolbox desk --dry-run) gcloud auth login"
sh -c "\$(k8s-toolbox desk --dry-run) gcloud config set project coastal-sunspot-206412"
sh -c "\$(k8s-toolbox desk --dry-run) gcloud compute instances list"

EOF

chmod +x /tmp/gcloud-login.sh

for ((i=1; i<=$NB_USER; i++))
do
    USER="k8s$i"
    export HOME="/home/$USER"
    sudo su - "$USER" -c "/tmp/gcloud-login.sh"
done
