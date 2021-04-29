#!/bin/bash

set -e
SCRIPT_PATH=$(cd "$(dirname "$0")"; pwd)
# shellcheck source=env.sh
. "$SCRIPT_PATH"/env.sh

cd "$SCRIPT_PATH"/deployment

if [[ -z $1 ]]; then
  LAST_BUILD=`aws s3 ls callisto-sih-test-us-east-1/callisto-sih-test/ | grep PRE | sed -e 's/.*PRE .*-//;s/\/$//' | sort -nr | head -1`
  ((LAST_BUILD++))
  export VERSION=${BASE_VERSION}-${LAST_BUILD}
else
  # Force build number via param
  export VERSION=$BASE_VERSION-$1
fi
echo "Deploying: ${VERSION}"

./build-s3-dist.sh $DIST_OUTPUT_BUCKET $SOLUTION_NAME $VERSION

aws s3 sync ./regional-s3-assets/ s3://${DIST_OUTPUT_BUCKET}-${REGION}/${SOLUTION_NAME}/${VERSION}/ --acl bucket-owner-full-control
aws s3 sync ./global-s3-assets/ s3://${DIST_OUTPUT_BUCKET}-${REGION}/${SOLUTION_NAME}/${VERSION}/ --acl bucket-owner-full-control

export TEMPLATE_URL=https://${DIST_OUTPUT_BUCKET}-${REGION}.s3.amazonaws.com/${DIST_OUTPUT_BUCKET}/${VERSION}/serverless-image-handler.template
echo TEMPLATE_URL=${TEMPLATE_URL}

aws cloudformation update-stack --stack-name  ${CLOUDFORMATION_STACK} --template-url ${TEMPLATE_URL} --capabilities CAPABILITY_NAMED_IAM --parameters "ParameterKey=SourceBuckets,UsePreviousValue=true"

aws cloudfront create-invalidation --distribution-id ${CLOUDFRONT_ID} --paths '/*'
