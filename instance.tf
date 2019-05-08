

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
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t3.small"
  name                    = "initial_db_david"
  username                = "david"
  password                = "mysqldavid"
  identifier_prefix       = "dheerema"
  allocated_storage       = 10
  skip_final_snapshot     = true
  db_subnet_group_name    = "${aws_db_subnet_group.mysubnet.name}"
  vpc_security_group_ids  = ["${aws_security_group.db.id}"]
}


resource "aws_instance" "demo" {
  count = "${var.instance_count}"
  user_data = <<EOT
  #cloud-config
  preserve_hostname: false
  manage_etc_hosts: true
  hostname: demo-${count.index}-david
  fqdn: demo-${count.index}-david
  write_files:
    - content: |
        DB_HOST= "${aws_db_instance.db.address}"
        DB_DB= "${aws_db_instance.db.name}"
        DB_USER= "${aws_db_instance.db.username}"
        DB_PASS= "${aws_db_instance.db.password}"
      path: /etc/nodejs.env
  runcmd:
    - [sudo, systemctl, enable, hello.service]
    - [sudo, systemctl, start, hello.service]
EOT
  ami                         = "${data.aws_ami.nodejs-demo-ami.id}"
  instance_type               = "t3.small"
  associate_public_ip_address = true
  subnet_id                   = "${element(aws_subnet.private.*.id, count.index)}"
  key_name                    = "${var.prefix}" # ssh key name
  vpc_security_group_ids      = ["${aws_security_group.demo.id}"]

  tags {
    Name = "${var.prefix}"
  }
}

# Create a new load balancer
resource "aws_elb" "davidselb" {
  name               = "iac-terraform-davidselb"
  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 30
  }

  instances                   = ["${aws_instance.demo.*.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  subnets                     = ["${aws_subnet.public.*.id}"]
  security_groups             = ["${aws_security_group.elb.id}"]

  tags = {
    Name = "david-terraform-elb"
  }
}


data "aws_route53_zone" "selected" {
  name         = "iac.trainings.jambit.de"

}

resource "aws_route53_record" "www" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "dheerema.iac.trainings.jambit.de"
  type    = "A"

  alias {
    name                   = "${aws_elb.davidselb.dns_name}"
    zone_id                = "${aws_elb.davidselb.zone_id}"
    evaluate_target_health = true
  }
}


output "elb_name" {
  value = "${aws_elb.davidselb.dns_name}"
}

######### Subnet groups ##############

resource "aws_db_subnet_group" "mysubnet" {
  name       = "david_subnet"
  subnet_ids = ["${aws_subnet.private.*.id}"]

  tags = {
    Name = "My DB subnet group"
  }
}

######### Security Groups ###########

resource "aws_security_group" "elb" {
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
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

resource "aws_security_group" "db" {
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.demo.id}"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    security_groups = ["${aws_security_group.demo.id}"]
  }
}

resource "aws_security_group" "demo" {
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    security_groups = ["${aws_security_group.elb.id}"]
  }

  tags {
    Name = "${var.prefix}"
  }
}
