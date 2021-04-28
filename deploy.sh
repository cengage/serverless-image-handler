#!/bin/bash

set -e
SCRIPT_PATH=$(cd "$(dirname "$0")"; pwd)
# shellcheck source=env.sh
. "$SCRIPT_PATH"/env.sh

cd "$SCRIPT_PATH"/deployment

./build-s3-dist.sh $DIST_OUTPUT_BUCKET $SOLUTION_NAME $VERSION

aws s3 sync ./regional-s3-assets/ s3://$DIST_OUTPUT_BUCKET-$REGION/$SOLUTION_NAME/$VERSION/ --acl bucket-owner-full-control
aws s3 sync ./global-s3-assets/ s3://$DIST_OUTPUT_BUCKET-$REGION/$SOLUTION_NAME/$VERSION/ --acl bucket-owner-full-control

TEMPLATE_URL=https://${DIST_OUTPUT_BUCKET}-${REGION}.s3.amazonaws.com/${DIST_OUTPUT_BUCKET}/${VERSION}/serverless-image-handler.template
echo TEMPLATE_URL=${TEMPLATE_URL}

aws cloudformation update-stack --stack-name  ${CLOUDFORMATION_STACK} --template-url ${TEMPLATE_URL} --capabilities CAPABILITY_NAMED_IAM --parameters "ParameterKey=SourceBuckets,UsePreviousValue=true"