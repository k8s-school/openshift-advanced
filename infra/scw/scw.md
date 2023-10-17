```
# Install cli
curl -s https://raw.githubusercontent.com/scaleway/scaleway-cli/master/scripts/get.sh | sh

# Init
# Command is displayed in the scaleway console after having created the key
scw init  access-key=XXX secret-key=YYY organization-id=13d35988-c094-471f-9a1c-0d62097a08f3  project-id=13d35988-c094-471f-9a1c-0d62097a08f3

# List images
scw marketplace image list

# Create instance
scw instance server create zone="fr-par-1" image=fedora_38 type=GP1-XS name=openshift root-volume=local:50GB

# List instances
scw instance server list
```