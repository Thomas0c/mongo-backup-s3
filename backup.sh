#!/bin/bash

set -e

: ${MONGO_HOST:?}
: ${MONGO_DB:?}
: ${S3_BUCKET:?}
: ${S3_PATH:?}
: ${AWS_ACCESS_KEY_ID:?}
: ${AWS_SECRET_ACCESS_KEY:?}
: ${DATE_FORMAT:?}
: ${PASS:?}
: ${FILE_PREFIX:?}

FOLDER=/backup
DUMP_OUT=dump

FILE_NAME=${FILE_PREFIX}$(date -u +${DATE_FORMAT}).tar.gz
ENC_FILE_NAME=${FILE_PREFIX}$(date -u +${DATE_FORMAT}).tar.gz.gpg

echo "Creating backup folder..."

rm -fr ${FOLDER} && mkdir -p ${FOLDER} && cd ${FOLDER}

echo "Starting backup..."

mongodump --host=${MONGO_HOST} --db=${MONGO_DB} --out=${DUMP_OUT}

echo "Compressing backup..."

tar -zcvf ${FILE_NAME} ${DUMP_OUT} && rm -fr ${DUMP_OUT}

echo "Encrypting file..."

gpg --cipher-algo AES256 --passphrase ${PASS} --symmetric ${FILE_NAME}

echo "Uploading to S3..."

aws s3api put-object --server-side-encryption=AES256 --bucket ${S3_BUCKET} --key ${S3_PATH}${ENC_FILE_NAME} --body ${ENC_FILE_NAME}

echo "Removing backup files..."

rm -f ${FILE_NAME}
rm -f ${ENC_FILE_NAME}

echo "Done!"
