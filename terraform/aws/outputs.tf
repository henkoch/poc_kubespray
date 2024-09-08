output "instance_public_ips" {
  value = aws_instance.kubespray_instance[*].public_ip
}

output "vpc_id" {
  value = aws_vpc.kubespray_vpc.id
}
