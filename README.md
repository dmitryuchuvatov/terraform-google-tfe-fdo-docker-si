# Terraform Enterprise Flexible Deployment Options - External Services mode on Docker (GCP)

This repository creates a new installation of TFE FDO in External Services mode on Docker (GCP)

# Diagram

![tfe_fdo_external_services_on_gcp](https://github.com/dmitryuchuvatov/terraform-google-tfe-fdo-docker-si/assets/119931089/4798d52c-8a18-451c-8ba2-d92f52e985eb)


# Prerequisites
+ Have Terraform installed as per the [official documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

+ Have **gcloud** installed as per the [official documentation](https://cloud.google.com/sdk/docs/install)

+ GCP account

+ TFE FDO license

# How To

## Clone repository

```
git clone https://github.com/dmitryuchuvatov/terraform-google-tfe-fdo-docker-si.git
```

## Change folder

```
cd terraform-google-tfe-fdo-docker-si
```

## Rename the file called `terraform.tfvars-sample` to `terraform.tfvars` and replace the values with your own.
The current content is below:

```
project             = "hc-8847d0246e5e4b388e7b87e6bf8"                              # GCP Project ID to create resources in
environment_name    = "fdo"                                                         # Name of the environment, used in naming of resources
region              = "europe-west4"                                                # Google Cloud region to deploy in
vpc_cidr            = "10.200.0.0/16"                                               # The IP range for the VPC in CIDR format
dns_zone            = "hc-8847d0246e5e4b388e7b87e6bf8.gcp.sbx.hashicorpdemo.com"    # DNS zone used in the URL. Can be obtained from Cloud DNS section on GCP portal
dns_record          = "fdo"                                                         # The record for your URL. Must be 4-5 letter, e.g. "tfe7" or "test2"
cert_email          = "dmitry.uchuvatov@hashicorp.com"                              # The email address used to register the certificate
db_password         = "Password1#"                                                  # Password for PostgreSQL database   
tfe_release         = "v202404-2"                                                   # TFE release version (https://developer.hashicorp.com/terraform/enterprise/releases)
tfe_password        = "Password1#"                                                  # TFE encryption password                         
tfe_license         = "02MV4U...."                                                  # Value from the license file
```

## Authenticate to gcloud

```
gcloud auth application-default login
```

Select your email account, click **Continue** and then, **Allow** - when it's done, you should see *You are now authenticated with the gcloud CLI!* page

## Terraform initialize

```
terraform init
```

## Terraform apply

```
terraform apply
```

When prompted, type **yes** and hit **Enter** to start provisioning GCP infrastructure and installing TFE FDO on it

You should see the similar result:

```
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

tfe_url = "https://fdo.hc-8847d0246e5e4b388e7b87e6bf8.gcp.sbx.hashicorpdemo.com"
```

## Next steps

[Provision your first administrative user](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/initial-admin-user) and start using Terraform Enterprise.
