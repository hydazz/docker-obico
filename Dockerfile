FROM hydaz/baseimage-alpine:latest

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OBICO_VERSION
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydaz"

# this is a really messy dockerfile but it works
RUN \
	echo "**** install build packages ****" && \
	apk add --no-cache --virtual=build-dependencies \
		jq \
    g++ \
    musl-dev \
    postgresql-dev \
    zlib-dev \
    jpeg-dev \
    libffi-dev && \
	echo "**** install packages ****" && \
	apk add -U --upgrade --no-cache \
		vim \
    ffmpeg \
    postgresql-libs \
    libxrender \
    libsm \
    fontconfig \
    py3-pip \
    py3-setuptools \
    wget \
    git && \
	echo "**** install obico-server ****" && \
	mkdir -p \
		/app/obico && \
	if [ -z ${OBICO_VERSION+x} ]; then \
		OBICO_VERSION=$(curl -sL "https://api.github.com/repos/TheSpaghettiDetective/obico-server/commits?ref=release" | \
			jq -r '.[0].sha' | cut -c1-8); \
	fi && \
	git clone -b release https://github.com/TheSpaghettiDetective/obico-server.git /tmp/ && \
  git checkout ${OBICO_VERSION} && \
  mv \
    /tmp/obico-server/backend \
    /tmp/obico-server/frontend \
    /tmp/obico-server/ml_api \
    /app/obico/ && \
	echo "**** setup backend ****" && \
  cd /app/obico/backend/ && \
  pip3 install -r requirements.txt && \
	echo "**** setup frontend ****" && \
	echo "**** setup ml_api ****" && \
  cd /app/obico/ml_api/ && \
  pip3 install -r requirements_x86_64.txt && \
  pip3 install -r requirements.txt && \
  wget --quiet -O model/model.weights $(cat model/model.weights.url | tr -d '\r') && \
	echo "**** cleanup ****" && \
	apk del --purge \
		build-dependencies && \
	rm -rf \
		/tmp/*


# copy local files
COPY root/ /

# ports and volumes
EXPOSE 3334
VOLUME /config
