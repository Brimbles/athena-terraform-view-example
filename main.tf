terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "eu-west-1"
  profile = "default"
}

#############################################
######## s3 bucket and some test data #######
#############################################

resource "aws_s3_bucket" "example" {
  bucket = "athenaviewtestbucket"

  tags = {
    Name        = "athenaviewtestbucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "object" {
  bucket = "athenaviewtestbucket"
  key    = "mockdata.csv"
  source = "mockdata.csv"
}

##################################################################
############## glue crawler and a role to run it #################
##################################################################

resource "aws_iam_role" "AWSGlueServiceRoleDefault" {
  name = "AWSGlueServiceRoleDefault"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "glue_service" {
    role = "${aws_iam_role.AWSGlueServiceRoleDefault.id}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
    role = "${aws_iam_role.AWSGlueServiceRoleDefault.id}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_glue_catalog_database" "athenaviewtestgluedb" {
  name = "athenaviewtestgluedb"
}

resource "aws_glue_crawler" "athenaviewtest_bucket_crawler" {
  database_name = aws_glue_catalog_database.athenaviewtestgluedb.name
  name          = "athenaviewtest_bucket_crawler"
  role          = aws_iam_role.AWSGlueServiceRoleDefault.arn

  s3_target {
    path = "s3://athenaviewtestbucket/"
  }
}


module "mockdataview" {
  source = "github.com/iconara/terraform-aws-athena-view"
  database_name = aws_glue_catalog_database.athenaviewtestgluedb.name
  name = "mockdataview"
  sql = "SELECT col0, col1 FROM athenaviewtestbucket"
  columns = [
    {
      name = "col0",
      hive_type = "string",
      presto_type = "varchar",
    },
    {
      name = "col1",
      hive_type = "string",
      presto_type = "varchar",
    }
  ]
}