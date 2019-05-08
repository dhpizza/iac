

data "aws_ami" "nodejs-demo-ami" {
  most_recent = true
  owners = ["self", "099720109477"]

  filter {
    name = "name"
    values = ["nodejs-rds-demo-*"]
  }
  filter {
    name = "state"
    values = ["available"]
  }
}


# Create a database server
resource "aws_db_instance" "db" {
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.small"
  name           = "initial_db_david"
  username       = "david"
  password       = "mysqldavid"
  identifier_prefix = "dheerema"
  allocated_storage = 10
  skip_final_snapshot = true
  db_subnet_group_name = "${aws_db_subnet_group.mysubnet.name}"
  vpc_security_group_ids = ["${aws_security_group.db.id}"]
}

resource "aws_instance" "demo" {
  count = 1
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
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"


  key_name = "${var.prefix}" # ssh key name
  vpc_security_group_ids = ["${aws_security_group.demo.id}"]

  tags {
    Name = "${var.prefix}"
  }

  provisioner "file" {
    content = <<EOT
DB_HOST= "${aws_db_instance.db.address}"
DB_DB= "${aws_db_instance.db.name}"
DB_USER= "${aws_db_instance.db.username}"
DB_PASS= "${aws_db_instance.db.password}"
EOT
    destination = "/tmp/nodejs.env"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv -v /tmp/nodejs.env /etc/nodejs.env",
      "sudo systemctl enable hello.service",
      "sudo systemctl start hello.service"
    ]
  }

  connection {
    type     = "ssh"
    user     = "ubuntu"
  }
}

resource "aws_db_subnet_group" "mysubnet" {
  name       = "david_subnet"
  subnet_ids = ["${aws_subnet.private.*.id}"]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_security_group" "db" {
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "demo" {
  vpc_id = "${aws_vpc.vpc.id}"

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
