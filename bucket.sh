#!/bin/sh

# How to use:
# 
# 1. Set up AWS CLI (plenty of information around the web about that)
# 2. Set PROJECT_NAME to your project's name - remember, S3 bucket names have to be globally unique. Leaving 'com-example' won't work.
# 3. Set REGION to where you want the bucket to reside
# 4. Decide whether you need to change BRANCH value. 
# 5. Execute the file.
#
# Questions: Post at https://github.com/tomfa/aws-policies/issues

export PROJECT_NAME=com-example
export REGION=ap-southeast-2

# Change this if this script is part of your CI/CD pipeline and you're publishing all your branches in isolation. Leave as is in all other cases.
export BRANCH=master

# Do not touch these
export PREFIX=$PROJECT_NAME-$BRANCH-$REGION
export WRITE_POLICY=$PREFIX-write
export BUCKET=$PREFIX
export USER=$PREFIX-user

aws s3api create-bucket --bucket $BUCKET --acl private --region $REGION --create-bucket-configuration LocationConstraint=$REGION
sed "s/\[\[YOUR-BUCKET-NAME\]\]/$BUCKET/g" s3-template.json > s3.json
aws s3api put-bucket-policy --bucket $BUCKET --policy file://s3.json
sed "s/\[\[YOUR-BUCKET-NAME\]\]/$BUCKET/g" cf-template.json > cf.json
aws cloudfront create-distribution --distribution-config file://cf.json
sed "s/\[\[YOUR-BUCKET-NAME\]\]/$BUCKET/g" iam-template.json > iam.json
aws iam create-user --user-name $USER
aws iam create-policy --policy-name $WRITE_POLICY --policy-document file://iam.json

# This lists all policies, takes only ARN of our $WRITE_POLICY and uses sed to remove the JSON fluff stuff so we can use it on the next line
export POLICY_ARN=$( aws iam list-policies | grep arn | grep $WRITE_POLICY | sed -E -n 's#.*(arn:aws:[^"]+).*#\1#p' )

aws iam attach-user-policy --user-name $USER --policy-arn $POLICY_ARN
aws iam create-access-key --user-name $USER

rm iam.json s3.json cf.json

echo "Done."
