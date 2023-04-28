provider "google" {
  # Your GCP project ID
  project = "your-gcp-project-id"
  region  = "your-gcp-region"
}

locals {
  cluster_name = "your-cluster-name"
}

resource "google_container_cluster" "primary" {
  name               = local.cluster_name
  location           = var.region
  initial_node_count = var.initial_node_count

  # Define the master version
  min_master_version = var.min_master_version

  # Network and subnetwork settings
  network    = var.network
  subnetwork = var.subnetwork

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = var.disable_network_policy
    }
  }

  lifecycle {
    ignore_changes = [
      node_pool, # To prevent Terraform from trying to manage the default node pool
    ]
  }
}

resource "google_container_node_pool" "primary" {
  name       = "your-node-pool-name"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_pool_initial_node_count

  node_config {
    preemptible  = var.node_pool_preemptible
    machine_type = var.node_pool_machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    tags = ["your-node-pool-tag"]

    # Add the labels to the node config
    labels = {
      your_label_key = "your_label_value"
    }
  }

  autoscaling {
    min_node_count = var.node_pool_min_node_count
    max_node_count = var.node_pool_max_node_count
  }

  management {
    auto_repair  = var.node_pool_auto_repair
    auto_upgrade = var.node_pool_auto_upgrade
  }
}

# Replace the values in the variables with your specific parameters
variable "region" {
  default = "us-central1"
}

variable "network" {
  default = "default"
}

variable "subnetwork" {
  default = "default"
}

variable "cluster_secondary_range_name" {
  default = "your-cluster-secondary-range-name"
}

variable "services_secondary_range_name" {
  default = "your-services-secondary-range-name"
}

variable "initial_node_count" {
  default = 1
}

variable "min_master_version" {
  default = "1.21"
}

variable "node_pool_initial_node_count" {
  default = 3
}

variable "node_pool_machine_type" {
  default = "n1-standard-1"
}

variable "node_pool_preemptible" {
  default = false
}

variable "node_pool_min_node_count" {
  default = 1
}

variable "node_pool_max_node_count" {
  default = 5
}

variable "node_pool_auto_repair" {
  default = true
}

variable "node
