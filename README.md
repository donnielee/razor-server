## razor-server 생성하기

![razor-server configuration](https://github.com/donnielee/razor-server/blob/master/image2017-12-6%2011_11_40.png)

1. host machine에 사전에 /var/lib/razor/repo-store를 razor:razor 사용자:그룹에, /var/lib/pgsql을 postgres:postgres 사용자:그룹 권한으로 생성한다.(또는 root로 생성한후, chown razor:razor /var/lib/razor/repo-store 로 ownership을 변경해준다. 이 directory는 razor-server container와 공유하는 volume이다.

2. Razor Dockerfile 및 docker-compose.yml 이 다운로드된 directory에서 docker-compose up 명령어를 실행하면, 이미지가 build되면서 container가 실행된다. 

3. http://razor-server(또는 localhost 등)로 접속하여 razor-server가 동작하는 것을 확인한다. 또는, razor-server container에 접속하여 다음의 명령어를 실행해본다. # razor -u http://localhost:8080/api 

4. pxe server는 target node와 IP address를 통해서 접속을 해야하기 때문에, bootstrap.ipxe 파일안에 razor/pxe server의 IP address를 입력한 후 image build 및 run 실행하여야 한다. 그리고, repo-store에 포함할 OS image도 마찬가지로 razor-server container에 접속하여 razor-repository를 생성하여야 한다. 
```예) # razor create-repo --name=CentOS-6.7-x86_64-minimal --iso-url=file:///var/lib/razor/repo-store/CentOS-6.7-x86_64-minimal.iso --task=redhat```

        

## docker-compose에서 Volume 사용법

container는 transient한 특성때문에, 데이터의 저장 및 관리가 필요한 경우 volume을 구성하여 관리하며, 다음의 두가지 방법이 사용된다.

host machine에 container에 대응하는 directory를 사전에 생성하여 mapping하는 방법이며, 아래 예의 경우 사전에 host machine에 /data/razor라는 directory를 razor:razor 사용자 계정으로 생성해두어야 한다.

```
razorserver:

build: 
context: .
dockerfile: Dockerfile
command: /etc/razor/razor-entrypoint.sh
volumes:
- /data/razor:/var/lib/razor
networks:
- default
ports:
- 8080:8080
depends_on:
- "razordb"
```



사전에 directory를 생성하지 않고, docker-compose.yml에 volumes를 정의하고 여기에 정의한 volume을 container의 directory에 mapping 하는 방법

```
razordb:
build:
context: ./pg-96
dockerfile: Dockerfile-pg-96
volumes:
- pgsql:/var/lib/pgsql
networks:
- default
ports:
- 5432:5432
privileged: true

volumes:
pgsql:
```

This repo builds a couple docker containers used for kickstarting my openstack (RDO) server using puppet's razor app.
It expects your host already has a large storage space mounted at /data to be shared into the two containers. Since razor depends on a PXE/DHCP/TFTP server already running, a second GitHub project, spam4kev/pxe, should already be running on the host before starting this projects docker compose. Notes on how to run spam4kev/pxe can be found at that projects [README.md](http://github.com/spam4kev/pxe)

NOTE: I ran in to some trouble with the docker engine host already had dnsmasq running which had port 53 open, preventing the container from being able to bind. To resolve, I killed the dnsmasq process on the docker engine host.

-  Run the below commands to prep your workstation to spin up the razor server container, backend database container, and pxe boot container.
```bash
sudo mount <my NAS IP>:/media /media
#there should be all the needed OS ISO's under /media/BitTorrent/operating_systems/\<os name (eg; centos)>
sudo sh -c "curl -L https://github.com/docker/compose/releases/download/1.5.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
sudo chmod +x /usr/local/bin/docker-compose
mkdir -p /data/razor /data/razor/pgsql
chmod 777 /data/razor/pgsql
chmod 775 /data/razor
chown root /data/razor
git clone https://github.com/spam4kev/razor-server.git
cd ~
docker-compose --x-networking up #--x-networking due to bug: https://github.com/docker/compose/issues/2480
#cleanup
docker-compose rm
docker rmi spam4kev/razor-server spam4kev/pxe
sudo rm -rf /data/razor/pgsql/userdata/ /data/razor/repo-store/* /data/razor/razor-server.sh
```

-  Some troubleshooting steps

```bash
docker run -d --name razorserver_razordb -e POSTGRESQL_USER=razor -e POSTGRESQL_PASSWORD=mypass -e POSTGRESQL_DATABASE=razor_prd -v /data/razor/pgsql centos/postgresql-94-centos7

docker run -v /data/razor:/var/lib/razor -t -i --link razorserver_razordb --name razorserver_razorserver_1 centos sh
/var/log/razor-server/console.log" "/opt/razor-torquebox/jboss/bin/standalone.sh" \
        "-Djboss.server.log.dir=/var/log/razor-server" \
        "-b" "0.0.0.0" "-Dhttp.port=8150" \
        "-Dhttps.port=#{RAZOR_HTTPS_PORT}"
docker commit -m "centos + razor rpm" $(docker ps -lq) razor-test

docker run -t -i --name razorserver_razorserver_1 spam4kev/razor-server sh
docker exec -i -t razorserver_razorserver_1  bash
docker logs razorserver_razordb
psql -h razor_db -p 5432 -d razorserver_razordb -U razor
```


-  The below manual build steps have proven to work if all else fails

```bash

sed -i 's/razor_prd/\/\/razorserver_razordb_1\/razor_prd/' /etc/razor/config.yaml
curl -SL http://links.puppetlabs.com/razor-microkernel-latest.tar      | tar -xC /var/lib/razor/repo-store/
razor-admin -e production migrate-database
/etc/razor/razor-server.sh start
# CTRL-P + CTRL-Q to disconnect
```  
# razor-server
