output "tfe_url" {
  description = "URL for TFE login"
  value       = "https://${var.dns_record}.${var.dns_zone}"
}

