FROM --platform=linux/amd64 alpine:3.8 AS upx
RUN apk add --no-cache upx=3.94-r0

FROM --platform=linux/amd64 golang:1.12.5-alpine AS build

RUN apk add --no-cache \
    make \
    libgcc libstdc++ ucl \
    git

COPY --from=upx /usr/bin/upx /usr/bin/upx

RUN mkdir -p /go/src/github.com/hairyhenderson/gomplate
WORKDIR /go/src/github.com/hairyhenderson/gomplate
COPY . /go/src/github.com/hairyhenderson/gomplate

ARG TARGETOS
ARG TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH
RUN make bin/gomplate_${TARGETOS}-${TARGETARCH}-slim
# RUN make build-x compress-all
RUN mv bin/gomplate* /bin/

FROM scratch AS gomplate-linux

ARG BUILD_DATE
ARG VCS_REF
ARG TARGETOS
ARG TARGETARCH

LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.source="https://github.com/hairyhenderson/gomplate"

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /bin/gomplate_${TARGETOS}-${TARGETARCH} /gomplate

ENTRYPOINT [ "/gomplate" ]

FROM --platform=$BUILDPLATFORM alpine:3.9 AS gomplate-alpine

ARG BUILD_DATE
ARG VCS_REF
ARG TARGETOS
ARG TARGETARCH

LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.source="https://github.com/hairyhenderson/gomplate"

RUN apk add --no-cache ca-certificates
COPY --from=build /bin/gomplate_${TARGETOS}-${TARGETARCH}-slim /gomplate

ENTRYPOINT [ "/bin/gomplate" ]

FROM scratch AS gomplate-slim-linux

ARG BUILD_DATE
ARG VCS_REF
ARG TARGETOS
ARG TARGETARCH

LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.source="https://github.com/hairyhenderson/gomplate"

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /bin/gomplate_${TARGETOS}-${TARGETARCH}-slim /gomplate

ENTRYPOINT [ "/gomplate" ]

FROM mcr.microsoft.com/windows/nanoserver:1809 AS gomplate-windows
ARG TARGETOS
ARG TARGETARCH
COPY --from=build /bin/gomplate_${TARGETOS}-${TARGETARCH} /gomplate.exe

FROM mcr.microsoft.com/windows/nanoserver:1809 AS gomplate-slim-windows
ARG TARGETOS
ARG TARGETARCH
COPY --from=build /bin/gomplate_${TARGETOS}-${TARGETARCH}-slim /gomplate.exe

FROM scratch AS gomplate-slim-darwin
COPY --from=build /bin/gomplate_darwin-amd64-slim /gomplate

FROM gomplate-$TARGETOS AS gomplate
FROM gomplate-slim-$TARGETOS AS gomplate-slim
