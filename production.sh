set -e
cat etc/version.txt
read version
export version
echo "verion=$version is going up in test"
echo $version > etc/version.txt
envsubst < etc/docker-compose-template.yml > docker-compose.yml
cd homeca
git pull
eval "docker build . -t homeca_django_test:$version"
cd ..
docker-compose up -d website-upgrade
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:9008/api/health-check/)" != "200" ]]; do sleep 5; done
echo "start"
cp etc/homeca-upgrade.conf /etc/nginx/conf.d/homeca.conf
nginx -s reload
docker-compose up -d website
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:9004/api/health-check/)" != "200" ]]; do sleep 5; done
cp etc/homeca-stable.conf /etc/nginx/conf.d/homeca.conf
nginx -s reload
echo "done!"