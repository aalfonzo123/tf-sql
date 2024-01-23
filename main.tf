# data "google_compute_subnetwork" "authorized-subnetwork-data" {
#   self_link = var.authorized-subnetwork
#   region    = var.region
# }

data "google_secret_manager_secret_version" "mysql-root-password" {
  secret = "db_password"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "sql-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "mysql-instance" {
  name   = "mysql-instance"
  region = var.region

  database_version = "MYSQL_8_0"
  root_password = data.google_secret_manager_secret_version.mysql-root-password.secret_data
  deletion_protection = "false"
  
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-f1-micro"
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"
    ip_configuration {
      ipv4_enabled                                  = false   # no public IPv4 address
      private_network                               = var.vpc 
      enable_private_path_for_google_cloud_services = true

      #   authorized_networks {
      #     value = data.google_compute_subnetwork.authorized-subnetwork-data.ip_cidr_range
      #   }
    }

    


  }

}

# resource "google_sql_user" "sql_user" {
#   name     = "alfuser"
#   instance = google_sql_database_instance.mysql-instance.name
#   password = data.google_secret_manager_secret_version.mysql-root-password.secret_data
# }
