# [Choice] Ruby version (use -bullseye variants on local arm64/Apple Silicon): 4, 4.0, 4-bookworm, 4.0-bookworm, 4-bullseye, 4.0-bullseye
ARG VARIANT=4.0-bookworm
FROM ruby:${VARIANT}

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
  && apt-get purge -y imagemagick imagemagick-6-common

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends libffi-dev tzdata nodejs npm yarn libpq-dev sqlite3 pkg-config

#ARG NODE_VERSION="lts/*"
#RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1
