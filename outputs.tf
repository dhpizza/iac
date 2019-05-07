

output "public-ip" {
  value = "${aws_instance.demo.*.public_ip}"
}
