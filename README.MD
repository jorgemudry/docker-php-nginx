# PHP & Nginx from Ubuntu
This repo contains the necessary files to create a docker image containing PHP & Nginx from a base image of Ubuntu.

## Requirements
- git
- docker

## Steps to create the image
1. Clone the repo
```bash
git clone git@github.com:jorgemudry/docker-php-nginx.git
```
2. Login into docker
* Use the credentials of the repo where you want to push the image to
```bash
docker login -u {USERNAME} -p {PASSWORD}
```
3. Build and tag the image
```bash
docker build -t {repo-username}/{image-name}:{tag}
```
4. Push the image to the remote repository
```bash
docker push {repo-username}/{image-name}:{tag}
```