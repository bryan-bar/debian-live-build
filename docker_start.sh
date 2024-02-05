#!/bin/bash
set -eou

[ "${DEBUG:=false}" == 'true' ] && set -x && exec 6>&1 && exec 1>&2

SOURCE_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
OUT_DIR="$SOURCE_DIR/workspace"
CONTAINER_NAME="debian_live_builder"
IMAGE_NAME="debian:bookworm"
SRC="/src"
DST="/tmp"
NEW_SRC="$DST$SRC"
ENTRY_SCRIPT="entry.sh"
DNS=1.1.1.1

ERROR_CHECK () {
  RETURN_CODE=$1
  OUTPUT=$2
  if [ "$RETURN_CODE" != "0" ]
  then
    printf "ERROR: $OUTPUT\n"
  fi
}

docker run --interactive --detach --dns "$DNS" --cap-add=SYS_CHROOT --privileged --name "$CONTAINER_NAME" "$IMAGE_NAME"
docker cp "$SOURCE_DIR/$SRC" "$CONTAINER_NAME:$DST"
ISO_FILE=$(sudo docker container exec "$CONTAINER_NAME" bash -c "DEBUG=$DEBUG $NEW_SRC/$ENTRY_SCRIPT")
ERROR_CHECK "$?" "$ISO_FILE"

LAST_OUTPUT="${ISO_FILE##*$'\n'}"
docker cp "$CONTAINER_NAME:$LAST_OUTPUT" "$OUT_DIR"
docker rm "$CONTAINER_NAME" --force

[ "${DEBUG:=false}" == 'true' ] && exec 1>&6 && exec 6>&-

