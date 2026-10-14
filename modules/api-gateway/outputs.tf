output "api_id" {
  description = "Identifier of the API."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "URL of the endpoint, with https://."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "endpoint_domain_name" {
  description = "Domain of the endpoint, without protocol. CloudFront origin."
  value       = trimprefix(aws_apigatewayv2_api.this.api_endpoint, "https://")
}

output "vpc_link_security_group_id" {
  description = "Security group of the VPC link. The backend allows traffic from it."
  value       = aws_security_group.vpc_link.id
}
