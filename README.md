# Setup Vautlwarden on k3s
* https://github.com/dani-garcia/vaultwarden

## Install prerequisites
```
dnf install epel-release -y
dnf install argon2 -y
```

## Prepare config
```
cp -av setup.sh setup.local.sh
vim setup.local.sh
# change values
bash setup.local.sh
```

