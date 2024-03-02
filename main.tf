# VPC

resource "google_compute_network" "tfe_vpc" {
  project                 = var.project
  name                    = "${var.environment_name}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
}

# Subnet

resource "google_compute_subnetwork" "tfe_subnet" {
  name          = "${var.environment_name}-subnet"
  ip_cidr_range = var.vpc_cidr
  region        = var.region
  network       = google_compute_network.tfe_vpc.self_link
}

# Public IP

resource "google_compute_address" "tfe_ip" {
  name   = "${var.environment_name}-ip"
  region = var.region
}

# Firewall / Traffic Rules 

resource "google_compute_firewall" "tfe_firewall" {
  name    = "${var.environment_name}-firewall"
  network = google_compute_network.tfe_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "5432"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Compute Engine / VM

resource "google_compute_instance" "tfe_instance" {
  name                      = "${var.environment_name}-instance"
  machine_type              = "n1-standard-4"
  zone                      = "${var.region}-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = "60"
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.tfe_subnet.id

    access_config {
      nat_ip = google_compute_address.tfe_ip.address
    }
  }

  tags = [google_compute_firewall.tfe_firewall.name]

  metadata = {
    user-data = templatefile("${path.module}/scripts/cloud-init.tpl", {
      dns_record          = var.dns_record
      dns_zone            = var.dns_zone
      db_fqdn             = google_sql_database_instance.instance.private_ip_address
      db_name             = google_sql_database_instance.instance.name
      db_username         = google_sql_user.tfe_credentials.name
      db_password         = var.db_password
      gcp_project         = var.project
      storage_name        = google_storage_bucket.tfe_storage.name
      storage_credentials = google_service_account_key.tfe_bucket_access.private_key
      tfe_release         = var.tfe_release
      tfe_license         = var.tfe_license
      tfe_password        = var.tfe_password
      full_chain          = base64encode("${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}")
      private_key_pem     = base64encode("${acme_certificate.certificate.private_key_pem}")
    })
  }
}

# Cloud SQL (PostgreSQL database)

resource "google_compute_global_address" "private_ip_address" {
  project       = var.project
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.tfe_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta # https://github.com/hashicorp/terraform-provider-google/issues/16275#issuecomment-1825752152
  network                 = google_compute_network.tfe_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database" "tfe_database" {
  name     = "${var.environment_name}-database"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database_instance" "instance" {
  name             = "${var.environment_name}-database"
  database_version = "POSTGRES_14"
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-custom-4-16384"
    disk_size         = 50
    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.tfe_vpc.id
      enable_private_path_for_google_cloud_services = true
    }
  }

  deletion_protection = "false"
}

resource "google_sql_user" "tfe_credentials" {
  name     = "${var.environment_name}-username"
  instance = google_sql_database_instance.instance.name
  password = var.db_password
}

# Cloud Storage

resource "google_storage_bucket" "tfe_storage" {
  name                        = "${var.environment_name}-storage"
  storage_class               = "REGIONAL"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

# IAM for Cloud Storage

resource "google_service_account" "tfe_bucket_access" {
  account_id   = "tfe-bucket-access"
  display_name = "tfe-bucket-access"
}

resource "google_service_account_key" "tfe_bucket_access" {
  service_account_id = google_service_account.tfe_bucket_access.id
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_storage_bucket_iam_member" "tfe_bucket_access" {
  bucket = google_storage_bucket.tfe_storage.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.tfe_bucket_access.email}"
}

# DNS

resource "google_dns_record_set" "tfe" {
  name = "${var.dns_record}.${var.dns_zone}."
  type = "A"
  ttl  = 300

  managed_zone = "doormat-accountid"

  rrdatas = [google_compute_instance.tfe_instance.network_interface[0].access_config[0].nat_ip]
}

# SSL certificates

resource "tls_private_key" "cert_private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.cert_private_key.private_key_pem
  email_address   = var.cert_email
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.registration.account_key_pem
  common_name     = "${var.dns_record}.${var.dns_zone}"

  dns_challenge {
    provider = "gcloud"

    config = {
      GCE_PROJECT = var.project
    }
  }
}