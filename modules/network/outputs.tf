output "vpc_id" {
  description = "Identifier of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR range of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Identifiers of the public subnets, one per zone."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Identifiers of the private subnets, one per zone."
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Availability zones in use."
  value       = local.availability_zones
}
