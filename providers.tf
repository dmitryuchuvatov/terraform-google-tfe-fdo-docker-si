terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.16.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~>4"
    }

    acme = {
      source  = "vancluever/acme"
      version = "2.11.1"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  region = var.project
  zone   = var.region
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}