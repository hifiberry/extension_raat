# Use a base image appropriate for your build environment
FROM ubuntu:20.04

# Set up build dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y build-essential git pkg-config libglib2.0-dev libdbus-1-dev libasound2-dev

# Copy the RAAT source code into the container
COPY raat /opt/raat

# Compile the RAAT software
WORKDIR /opt/raat
RUN cd plugins; gdbus-codegen --interface-prefix org.mpris --generate-c-code mpris-interface org.mpris.MediaPlayer2.xml
RUN make TARGET=hifiberry64 CONFIG=release

# Create a new container for the binary
FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -yqq --no-install-recommends libasound2 curl alsa-tools alsa-utils && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -r raat && \
    useradd --no-log-init -r -g raat -u 2002 raat

# Copy the compiled binary from the build container
COPY --from=0 /opt/raat/bin/release/linux/aarch64/raat_app /usr/local/bin/raat_app
COPY --from=0 /opt/raat/bin/release/linux/aarch64/raatool /usr/local/bin/raattool

# Set up any additional configuration or dependencies
# (e.g., configure environment variables, install required libraries)

# Define the command to run the binary
CMD ["raat_app", "/etc/hifiberry_raat.conf" ]

USER raat
