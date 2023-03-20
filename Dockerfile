FROM debian:bullseye as builder

ARG NODE_VERSION=16.17.0
ARG YARN_VERSION=1.22.19

RUN apt-get update; apt install -y curl python-is-python3 pkg-config build-essential
RUN curl https://get.volta.sh | bash
ENV VOLTA_HOME /root/.volta
ENV PATH /root/.volta/bin:$PATH
RUN volta install node@${NODE_VERSION} yarn@${YARN_VERSION}

#######################################################################

RUN mkdir /app
WORKDIR /app

# Yarn will not install any package listed in "devDependencies" when NODE_ENV is set to "production"
# to install all modules: "yarn install --production=false"
# Ref: https://classic.yarnpkg.com/lang/en/docs/cli/install/#toc-yarn-install-production-true-false

# ENV NODE_ENV production

COPY . .
RUN echo "PORT=8080" > .env

# RUN npm install --global rimraf 

RUN yarn install && yarn run build
FROM debian:bullseye

LABEL fly_launch_runtime="nodejs"

COPY --from=builder /root/.volta /root/.volta
COPY --from=builder /app /app

# RUN npm install --global rimraf nodemon

WORKDIR /app
ENV NODE_ENV production
ENV WEB_MEMORY=128
ENV NODE_OPTIONS=--max_old_space_size=128

ENV PATH /root/.volta/bin:$PATH

RUN echo "PORT=8080" > .env

CMD [ "yarn", "run", "start" ]
