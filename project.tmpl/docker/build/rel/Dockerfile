ARG base_image_repo=quay.io/larryloi/schematic_base
ARG base_image_tag
FROM ${base_image_repo}:${base_image_tag}

ARG schematic_home=/home/schematic
ENV SCHEMATIC_HOME=${schematic_home}

ARG env_home=/home/env
ENV ENV_HOME=${env_home}

ARG app_home=/home/app
ENV APP_HOME=${app_home}
ENV HISTFILE=${APP_HOME}/.bash_history

# RUN apk -U upgrade && \
RUN mkdir -p ${APP_HOME}

WORKDIR ${APP_HOME}

COPY . .

# RUN apk add --no-cache \
#         freetds-dev mariadb-dev libpq-dev \
#         gcompat curl make && \
RUN chown -R 1001:0 ${SCHEMATIC_HOME} && \
    chmod -R g=u ${SCHEMATIC_HOME} && \
    chown -R 1001:0 ${APP_HOME} && \
    chmod -R g=u ${APP_HOME}

ARG project
ARG app
ARG version
ARG release_tag
ARG build_number
ARG app_source
ARG authors
ARG image_repo
ARG image_tag
ARG base_image_repo
ARG base_image_tag
ARG created_at

ENV PROJECT_NAME=#{projecct}
ENV APP_NAME=#{app}
ENV APP_VERSION=${version}-${release_tag}.${build_number}

LABEL org.opencontainers.image.title=${project}-${app} \
    org.opencontainers.image.version=${version}-${release_tag}.${build_number} \
    org.opencontainers.image.authors=${authors} \
    org.opencontainers.image.source=${app_source} \
    org.opencontainers.image.created=${created_at} \
    \
    org.larryloi.project=${project} \
    org.larryloi.app=${app} \
    org.larryloi.app.release=${version}-${release_tag}.${build_number} \
    org.larryloi.app.version=${version} \
    org.larryloi.app.release_tag=${release_tag} \
    org.larryloi.app.build_number=${build_number} \
    org.larryloi.maintainer=${authors} \
    \
    org.larryloi.image.repo=${image_repo} \
    org.larryloi.image.tag=${image_tag} \
    org.larryloi.image.name=${image_repo}:${image_tag} \
    \
    org.larryloi.base_image.repo=${base_image_repo} \
    org.larryloi.base_image.tag=${base_image_tag} \
    org.larryloi.base_image.name=${base_image_repo}:${base_image_tag}

USER 1001
