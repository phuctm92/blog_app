# syntax=docker/dockerfile:1
FROM ruby:3.1.2

ARG UID
ARG GID

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential curl git libpq-dev \
  && curl -sSL https://deb.nodesource.com/setup_18.x | bash - \
  && curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb https://dl.yarnpkg.com/debian/ stable main' | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update && apt-get install -y --no-install-recommends nodejs yarn \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean

# We're adding a custom `deploy` user with the host user's GID and UID
# so files created inside the container are owned by the host user.
RUN groupadd --gid $GID deploy
RUN adduser --uid $UID --gid $GID --shell /bin/bash --disabled-password deploy
RUN adduser deploy sudo

# Don't ask for a password when using `sudo`
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER deploy

WORKDIR /webapp

COPY --chown=deploy:deploy Gemfile /webapp/Gemfile
COPY --chown=deploy:deploy Gemfile.lock /webapp/Gemfile.lock

# Install bundler and run bundle install
RUN gem uninstall bundler
RUN gem install bundler -v 2.3.24
RUN bundle install --jobs "$(nproc)"

# Add a script to be executed every time the container starts.
# COPY docker-entrypoint-web.sh /usr/bin/
# RUN chmod +x /usr/bin/docker-entrypoint-web.sh
# ENTRYPOINT ["docker-entrypoint-web.sh"]
# EXPOSE 3000

# Configure the main process to run when running the image
# CMD ["rails", "server", "-b", "0.0.0.0"]
