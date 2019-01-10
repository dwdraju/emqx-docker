ARG BUILD_FROM

FROM $BUILD_FROM

# Define ARGs again to make them available after FROM
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REF
ARG ARCH
ARG QEMU_ARCH
ARG EMQX_VERSION
ARG EMQX_DELOPY

# Basic build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.dockerfile="docker/Dockerfile.alpine-tmpl" \
    org.label-schema.license="GNU" \
    org.label-schema.name="emqx" \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.description="EMQ (Erlang MQTT Broker) is a distributed, massively scalable, highly extensible MQTT messaging broker written in Erlang/OTP." \
    org.label-schema.url="http://emqx.io" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/emqx/emqx-docker" \
    maintainer="Raymond M Mouthaan <raymondmmouthaan@gmail.com>, Huang Rui <vowstar@gmail.com>, EMQ X Team <support@emqx.io>"

# tmp/qemu... is ignored if doesn't exist (i.e. for native builds)
COPY ./start.sh tmp/qemu-$QEMU_ARCH-stati* /usr/bin/

# Copy ARCHs to ENVs to make them available at runtime
ENV ARCH=$ARCH
ENV DELOPY=$EMQX_DELOPY
ENV EMQX_VERSION=$EMQX_VERSION
ENV EMQX_DEPS_DEFAULT_VSN=$EMQX_VERSION

RUN apk add --no-cache --virtual .build-deps \
                dpkg-dev dpkg \
                gcc \
                g++ \
                libc-dev \
                linux-headers \
                make \
                autoconf \
                ncurses-dev \
                openssl-dev \
                unixodbc-dev \
                lksctp-tools-dev \
                tar \
                git \
                wget \
                curl \
                bsd-compat-headers \
                coreutils \
                openssh-client \
                openssh-keygen \
        && cd / && git clone -b ${EMQX_VERSION} https://github.com/emqx/emqx-rel /emqx \
        && cd /emqx \
        && make \
        && mkdir -p /opt && mv /emqx/_rel/emqx /opt/emqx \
        && cd / && rm -rf /emqx \
        && ln -s /opt/emqx/bin/* /usr/local/bin/ \
        # removing fetch deps and build deps
		&& apk --purge del .build-deps \
        && rm -rf /var/cache/apk/* root/.cache /tmp/* /tmp/.??* \
        && rm -rf /usr/local/lib/erlang /usr/local/bin/rebar3


WORKDIR /opt/emqx

RUN adduser -D -u 1000 emqx

RUN chgrp -Rf emqx /opt/emqx && chmod -Rf g+w /opt/emqx \
      && chown -Rf emqx /opt/emqx

USER emqx

VOLUME ["/opt/emqx/log", "/opt/emqx/data", "/opt/emqx/lib", "/opt/emqx/etc"]

# emqx will occupy these port:
# - 1883 port for MQTT
# - 8883 port for MQTT(SSL)
# - 8083 for WebSocket/HTTP
# - 8084 for WSS/HTTPS
# - 8080 for mgmt API
# - 18083 for dashboard
# - 4369 for port mapping
# - 5369 for gen_rpc port mapping
# - 6369 for distributed node
EXPOSE 1883 8883 8083 8084 8080 18083 4369 5369 6369 6000-6999

# start emqx and initial environments
CMD ["/usr/bin/start.sh"]
