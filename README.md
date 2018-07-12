# BUILD

1. REPO = Repo Apps
2. BRANCH = Branch Repo
3. DIR = Name Directory Apps
4. SERVER_NAME = Server Name in Nginx
5. ROOTDIR = RootDir index
6. PHPVERSION = 7.x



`docker build --build-arg REPO=http://<user>:<password>@gitlab.com/project/web.git --build-arg BRANCH=master --build-arg DIR=web --build-arg SERVER_NAME=web.com --build-arg ROOTDIR=web/public --build-arg PHPVERSION=7.x --build-arg ENV=development -t web:latest .`

## RUNNING

`docker run -d --name web -h web --restart=always -p 80:80 web:latest`

