az account list --refresh
az ad sp create-for-rbac  --role Contributor --name openshift --scopes /subscriptions/c2b96932-405b-480d-8b73-24f86be1cdb6
az ad sp create-for-rbac  --role "User Access Administrator" --name openshift --scopes /subscriptions/c2b96932-405b-480d-8b73-24f86be1cdb6
