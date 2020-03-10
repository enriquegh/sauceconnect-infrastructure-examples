output "proxy_public_ip" {
  value = aws_instance.proxy.public_ip
}
output "proxy_private_ip" {
  value = aws_instance.proxy.private_ip
}
output "sc_app_private_ip" {
  value = aws_instance.sc_app.private_ip
}