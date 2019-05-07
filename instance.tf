

data "aws_ami" "nodejs-demo-ami" {
  most_recent = true
  owners = ["self", "099720109477"]

  filter {
    name = "name"
    values = ["nodejs-demo-*"]
  }
  filter {
    name = "state"
    values = ["available"]
  }
}

data "aws_route53_zone" "selected" {
  name         = "iac.trainings.jambit.de."
}

resource "aws_route53_record" "www" {
  count = "${length(aws_instance.demo.*.id)}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "demo-david-${count.index}"
  type    = "A"
  ttl     = "60" # time  in sec to cache domain name
  records = ["${element(aws_instance.demo.*.public_ip, count.index)}"]
}

resource "aws_instance" "demo" {
  count = 4
  user_data = <<EOT
  #cloud-config
  preserve_hostname: false
  manage_etc_hosts: true
  hostname: demo-${count.index}-david
  fqdn: demo-${count.index}-david
EOT
  ami = "${data.aws_ami.nodejs-demo-ami.id}"
  instance_type = "t3.small"

  associate_public_ip_address = true
  subnet_id = "${data.aws_subnet.subnet.id}"


  key_name = "${var.prefix}" # ssh key name
  vpc_security_group_ids = [
    "${aws_security_group.demo.id}"
  ]

  tags {
    Name = "${var.prefix}"
  }
  /*
  root_block_device {
    volume_size = 12
    volume_type = "gp2"
  }*/

}


resource "aws_security_group" "demo" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.prefix}"
  }


}
