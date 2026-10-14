resource "aws_secretsmanager_secret" "this" {
  for_each = toset(var.secret_names)

  name                    = "secret-${var.product}-${replace(lower(each.key), "_", "-")}-${var.environment}"
  description             = "Application secret ${each.key}. The value is loaded manually, never by Terraform."
  recovery_window_in_days = var.recovery_window_days
}
