# terraform_athena_view


## What is this?
An example to show how an Athena view can be deployed programatically with terraform

## What is deployed
- A bucket and a small test file
- a crawler and a target glue db
- compiles and deploys and athena view using the module found in github.com/iconara/terraform-aws-athena-view

## Usage
- Deploy the resources to AWS.
- run the crawler.
- select from the view to confirm it works as expected.