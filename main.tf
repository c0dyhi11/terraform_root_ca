variable "country" { default = "US" }
variable "state" { default = "Texas" }
variable "city" { default = "Austin" }
variable "org" { default = "Initech" }
variable "unit" { default = "Technology" }
variable "domain" { default = "initech.local" }
variable "email" { default = "peter@initech.local" }
variable "intermediate_names" { default = ["us-west-1", "us-east-1", "us-central-1", "eu-west-1", "ap-east-1"] }

locals {
    root_dir = "${abspath(path.module)}/root_ca"
    intermediate_dir = "${abspath(path.module)}/root_ca/intermediate"
    scripts_dir = "${abspath(path.module)}/root_ca/scripts"
}

resource "random_string" "root_ca_password" {
    length = 20
    min_upper = 2
    min_lower = 2
    min_numeric = 2
    min_special = 2
    override_special = "$!?@*"
}

data "template_file" "root_ca_openssl_config" {
    template = file("templates/openssl/ca.cnf")
    vars = {
        ROOT_DIR = local.root_dir
        COUNTRY = var.country
        STATE = var.state
        CITY = var.city
        ORG = var.org
        UNIT = var.unit
        EMAIL = var.email
    }
}

data "template_file" "intermediate_openssl_config" {
    template = file("templates/openssl/intermediate.cnf")
    vars = {
        INTERMEDIATE_DIR = local.intermediate_dir
        COUNTRY = var.country
        STATE = var.state
        CITY = var.city
        ORG = var.org
        UNIT = var.unit
        EMAIL = var.email
    }
}

data "template_file" "gen_ca" {
    template = file("templates/scripts/gen_ca.sh")
    vars = {
        ROOT_DIR = local.root_dir
        INTERMEDIATE_DIR = local.intermediate_dir
        PASSWORD = random_string.root_ca_password.result
        COUNTRY = var.country
        STATE = var.state
        CITY = var.city
        ORG = var.org
        UNIT = var.unit
        DOMAIN = var.domain
    }
}

data "template_file" "gen_intermediate" {
    template = file("templates/scripts/gen_intermediate.sh")
    vars = {
        ROOT_DIR = local.root_dir
        INTERMEDIATE_DIR = local.intermediate_dir
        PASSWORD = random_string.root_ca_password.result
        COUNTRY = var.country
        STATE = var.state
        CITY = var.city
        ORG = var.org
        UNIT = var.unit
        DOMAIN = var.domain
    }
}

resource "local_file" "root_ca_openssl_config" {
    content = data.template_file.root_ca_openssl_config.rendered
    filename = "${local.root_dir}/openssl.cnf"
    file_permission = "0644"
}

resource "local_file" "intermediate_openssl_config" {
    content = data.template_file.intermediate_openssl_config.rendered
    filename = "${local.intermediate_dir}/openssl.cnf"
    file_permission = "0644"
}

resource "local_file" "gen_ca" {
    content = data.template_file.gen_ca.rendered
    filename = "${local.scripts_dir}/gen_ca.sh"
    file_permission = "0755"
}

resource "local_file" "gen_intermediate" {
    content = data.template_file.gen_intermediate.rendered
    filename = "${local.scripts_dir}/gen_intermediate.sh"
    file_permission = "0755"
}

resource "null_resource" "gen_ca"{
    depends_on = [local_file.gen_ca]
    provisioner "local-exec" {
        command = <<-EOC
            bash ${local.scripts_dir}/gen_ca.sh
        EOC
    }
}

resource "random_string" "intermediate_ca_password" {
    count = length(var.intermediate_names)
    length = 20
    min_upper = 2
    min_lower = 2
    min_numeric = 2
    min_special = 2
    override_special = "$!?@*"
}

resource "null_resource" "gen_intermediates"{
    count = length(var.intermediate_names)
    depends_on = [null_resource.gen_ca]
    provisioner "local-exec" {
        command = <<-EOC
            bash ${local.scripts_dir}/gen_intermediate.sh '${var.intermediate_names[count.index]}' '${element(random_string.intermediate_ca_password.*.result, count.index)}'
        EOC
    }
    provisioner "local-exec" {
        when = destroy
        command = <<-EOD
            rm -rf ${local.root_dir}
        EOD
    }
}