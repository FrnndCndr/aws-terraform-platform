resource "aws_route53_zone" "this" {
  name    = var.domain_name
  comment = "Domain of ${var.product}"

  lifecycle {
    prevent_destroy = true
  }
}
