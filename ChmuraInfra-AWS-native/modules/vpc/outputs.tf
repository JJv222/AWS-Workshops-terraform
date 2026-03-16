output "vpc_id" {
	value = aws_vpc.this.id
}

# lista publicznych podsieci
output "public_subnets" {
	value = aws_subnet.public[*].id
}

# pierwszy publiczny subnet (frontend)
output "frontend_subnet_id" {
	value = aws_subnet.public[0].id
}

# drugi publiczny subnet (backend) jeśli występuje
output "backend_subnet_id" {
	value = aws_subnet.public[1].id
}

# lista prywatnych podsieci dla RDS
output "private_subnets" {
	value = aws_subnet.private[*].id
}