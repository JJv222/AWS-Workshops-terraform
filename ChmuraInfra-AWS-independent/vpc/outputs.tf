output "vpc_id" {
	value = aws_vpc.this.id
}


output "public_subnets" {
	value = aws_subnet.public[*].id
}


output "frontend_subnet_id" {
	value = aws_subnet.public[0].id
}


output "backend_subnet_id" {
	value = aws_subnet.public[1].id
}


output "private_subnets" {
	value = aws_subnet.private[*].id
}