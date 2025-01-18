helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add vaultwarden https://guerzon.github.io/vaultwarden
helm repo update

genpasswd ()
{ 
    local l=$1;
    [ "$l" == "" ] && l=30;
    tr -dc A-Za-z0-9_=., < /dev/urandom | head -c ${l} | xargs
}


for p in argon2 
do
   which $p || ( echo cmd: $p not found, please install first ; exit 1)
done

test -d runtime && echo ERROR remove ./runtime dir first
test -d ./runtime && exit 1
mkdir ./runtime
chmod 700 ./runtime

export ADMIN_PASSWORD="$(genpasswd)"
echo "ADMIN_PASSWORD is: $ADMIN_PASSWORD  keep it in save place and NEVER share"


export FQDN=vault.domain.tld
export NAMESPACE=vaultwarden
export MYSQL_ROOT_PW="$(genpasswd)"
export MYSQL_PW="$(genpasswd)"
export STORAGE_CLASS=local-path
export ADMIN_TOKEN="$(echo -n $ADMIN_PASSWORD | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4 | sed 's#\$#\\$#g' )"

echo "
NAMESPACE=$NAMESPACE
MYSQL_ROOT_PW=$MYSQL_ROOT_PW
MYSQL_PW=$MYSQL_PW
STORAGE_CLASS=$STORAGE_CLASS
FQDN=$FQDN
ADMIN_TOKEN=$ADMIN_TOKEN
" > ./runtime/env.sh
chmod 600 ./runtime/env.sh

for y in *.yml
do
  cp -av $y ./runtime/$y
  sed -i "s/__NAMESPACE__/$NAMESPACE/g"          ./runtime/$y
  sed -i "s/__FQDN__/$FQDN/g"                    ./runtime/$y
  sed -i "s/__ADMIN_TOKEN__/$ADMIN_TOKEN/g"      ./runtime/$y
  sed -i "s/__STORAGE_CLASS__/$STORAGE_CLASS/g"  ./runtime/$y
  sed -i "s/__MYSQL_ROOT_PW__/$MYSQL_ROOT_PW/g"  ./runtime/$y
  sed -i "s/__MYSQL_PW__/$MYSQL_PW/g"            ./runtime/$y
done

kubectl apply -f ./runtime/01_namespace.yml
kubectl config set-context --current --namespace $NAMESPACE

helm install mariadb bitnami/mariadb -f ./runtime/02_values-mariadb.yml

echo waiting 10s
sleep 10

helm install vaultwarden-release vaultwarden/vaultwarden --namespace $NAMESPACE -f ./runtime/03_values-vaultwarden.yml

