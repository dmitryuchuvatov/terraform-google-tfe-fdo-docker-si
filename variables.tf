variable "project" {
  type        = string
  description = "GCP Project ID to create resources in"
}

variable "environment_name" {
  type        = string
  description = "Name used to create and tag resources"
}

variable "region" {
  type        = string
  description = "Google Cloud region to deploy in"
}

variable "vpc_cidr" {
  type        = string
  description = "The IP range for the VPC in CIDR format"
}

variable "dns_zone" {
  description = "DNS zone used in the URL. Can be obtained from Cloud DNS section on GCP portal"
  type        = string
}

variable "dns_record" {
  description = "The record for your URL"
  type        = string
}

variable "cert_email" {
  description = "Email address used to obtain SSL certificate"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
}

variable "tfe_release" {
  description = "TFE release"
  type        = string
}

variable "tfe_license" {
  description = "TFE license"
  type        = string
}

variable "tfe_password" {
  description = "TFE password"
  type        = string
}