FROM alpine:latest as builder

# Install build dependencies
RUN apk update && apk add --no-cache \
    build-base \
    git \
    pkgconf \
    glib-dev \
    dbus-dev \
    alsa-lib-dev

# Copy the RAAT source code into the container
COPY raat /opt/raat

# Compile the RAAT software
WORKDIR /opt/raat
RUN cd plugins && gdbus-codegen --interface-prefix org.mpris --generate-c-code mpris-interface org.mpris.MediaPlayer2.xml
RUN make TARGET=hifiberry64 CONFIG=release

# Create a new container for the binary
FROM alpine:latest

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    alsa-lib \
    curl \
    glib \
    alsa-utils && \
    addgroup -S raat && \
    adduser -S -G raat -u 2002 raat 

# Copy the compiled binary from the build container
COPY --from=builder /opt/raat/bin/release/linux/aarch64/raat_app /usr/local/bin/raat_app
COPY --from=builder /opt/raat/bin/release/linux/aarch64/raatool /usr/local/bin/raatool

# Set up any additional configuration or dependencies
# (e.g., configure environment variables, install required libraries)

# Define the command to run the binary
CMD ["raat_app", "/etc/hifiberry_raat.conf"]

USER raat
