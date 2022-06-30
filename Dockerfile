FROM node:16.15.1-bullseye AS builder

ARG NODE_ENV=production

WORKDIR /misskey

# <<<<<<< HEAD
# COPY . ./  # Do NOT copy everything in one go please

RUN apt-get update
RUN apt-get install -y build-essential
RUN rm -rf .git
# RUN git submodule update --init  # should actually be done at clone time.
# RUN yarn install
# RUN yarn build
# =======
# ENV BUILD_DEPS autoconf automake file g++ gcc libc-dev libtool make nasm pkgconfig python3 zlib-dev git
# FROM base AS builder
# RUN apk add --no-cache $BUILD_DEPS

COPY package.json ./
COPY packages/backend/package.json ./packages/backend/package.json
COPY packages/client/package.json ./packages/client/package.json
COPY packages/sw/package.json ./packages/sw/package.json

RUN yarn install

# RUN NO_POSTINSTALL=1 yarn install
# RUN cd packages/backend && yarn --force install
# RUN cd packages/client && yarn install
# RUN cd packages/sw && yarn install

COPY . ./

# RUN  git submodule update --init && \
RUN yarn build
	# rm -rf .git
# >>>>>>> edbb8b435 (chore(docker): improve layers caching)

FROM node:16.15.1-bullseye-slim AS runner

WORKDIR /misskey

RUN apt-get update
RUN apt-get install -y ffmpeg tini

COPY --from=builder /misskey/node_modules ./node_modules
COPY --from=builder /misskey/packages/backend/node_modules ./packages/backend/node_modules
COPY --from=builder /misskey/packages/client/node_modules ./packages/client/node_modules

COPY --from=builder /misskey/built ./built
COPY --from=builder /misskey/packages/backend/built ./packages/backend/built
COPY . ./

ENV NODE_ENV=production
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["npm", "run", "migrateandstart"]
