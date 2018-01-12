FROM cpcsdk/crossdev
MAINTAINER Krusty/Benediction



RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qy unrar


