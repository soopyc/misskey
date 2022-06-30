FROM node:18.0.0-alpine3.15 AS base

ARG NODE_ENV=production

WORKDIR /misskey

ENV BUILD_DEPS autoconf automake file g++ gcc libc-dev libtool make nasm pkgconfig python3 zlib-dev git

FROM base AS builder

RUN apk add --no-cache $BUILD_DEPS

COPY package.json ./
COPY packages/backend/package.json ./packages/backend/package.json
COPY packages/client/package.json ./packages/client/package.json
COPY packages/sw/package.json ./packages/sw/package.json

RUN NO_POSTINSTALL=1 yarn install
RUN cd packages/backend && yarn --force install
RUN cd packages/client && yarn install
RUN cd packages/sw && yarn install

COPY . ./

RUN  git submodule update --init && \
	yarn build && \
	rm -rf .git

FROM base AS runner

RUN apk add --no-cache \
	ffmpeg \
	tini

ENTRYPOINT ["/sbin/tini", "--"]

COPY --from=builder /misskey/node_modules ./node_modules
COPY --from=builder /misskey/packages/backend/node_modules ./packages/backend/node_modules
COPY --from=builder /misskey/packages/client/node_modules ./packages/client/node_modules

COPY --from=builder /misskey/built ./built
COPY --from=builder /misskey/packages/backend/built ./packages/backend/built
COPY . ./

ENV NODE_ENV=production
CMD ["npm", "run", "migrateandstart"]

