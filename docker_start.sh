#!/bin/bash
set -eou

SOURCE_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
CONTAINER_NAME="debian_live_builder"
IMAGE_NAME="debian:bookworm"
SRC="/src"
DST="/tmp"
NEW_SRC="$DST$SRC"
ENTRY_SCRIPT="entry.sh"
DNS=1.1.1.1

sudo docker run --tty --dns "$DNS" --cap-add=SYS_CHROOT --priviledged --name "$CONTAINER_NAME" "$IMAGE_NAME"
sudo docker cp "$SOURCE_DIR/$SRC" "$CONTAINER_NAME:$DST"
ISO_FILE=$(sudo docker container exec "$CONTAINER_NAME" bash -c "$NEW_SRC/$ENTRY_SCRIPT")
RC="$?"
if [ "$RC" -ne 0 ]
then
  printf "ERROR: $ISO_FILE" >&2
  exit $RC
fi

sudo docker cp "$CONTAINER_NAME:$ISO_FILE" "$SOURCE_DIR"

