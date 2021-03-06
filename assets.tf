# Self-hosted Kubernetes bootstrap-manifests
resource "template_dir" "bootstrap-manifests" {
  source_dir      = "${path.module}/resources/bootstrap-manifests"
  destination_dir = "${var.asset_dir}/bootstrap-manifests"

  vars {
    hyperkube_image = "${var.container_images["hyperkube"]}"
    etcd_servers    = "${join(",", formatlist("https://%s:2379", var.etcd_servers))}"

    cloud_provider = "${var.cloud_provider}"
    pod_cidr       = "${var.pod_cidr}"
    service_cidr   = "${var.service_cidr}"
  }
}

# Self-hosted Kubernetes manifests
resource "template_dir" "manifests" {
  source_dir      = "${path.module}/resources/manifests"
  destination_dir = "${var.asset_dir}/manifests"

  vars {
    hyperkube_image        = "${var.container_images["hyperkube"]}"
    pod_checkpointer_image = "${var.container_images["pod_checkpointer"]}"
    kubedns_image          = "${var.container_images["kubedns"]}"
    kubedns_dnsmasq_image  = "${var.container_images["kubedns_dnsmasq"]}"
    kubedns_sidecar_image  = "${var.container_images["kubedns_sidecar"]}"

    etcd_servers = "${join(",", formatlist("https://%s:2379", var.etcd_servers))}"

    cloud_provider        = "${var.cloud_provider}"
    pod_cidr              = "${var.pod_cidr}"
    service_cidr          = "${var.service_cidr}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
    kube_dns_service_ip   = "${cidrhost(var.service_cidr, 10)}"

    ca_cert            = "${base64encode(var.ca_certificate == "" ? join(" ", tls_self_signed_cert.kube-ca.*.cert_pem) : var.ca_certificate)}"
    server             = "${format("https://%s:443", element(var.api_servers, 0))}"
    apiserver_key      = "${base64encode(tls_private_key.apiserver.private_key_pem)}"
    apiserver_cert     = "${base64encode(tls_locally_signed_cert.apiserver.cert_pem)}"
    serviceaccount_pub = "${base64encode(tls_private_key.service-account.public_key_pem)}"
    serviceaccount_key = "${base64encode(tls_private_key.service-account.private_key_pem)}"

    etcd_ca_cert     = "${base64encode(tls_self_signed_cert.etcd-ca.cert_pem)}"
    etcd_client_cert = "${base64encode(tls_locally_signed_cert.client.cert_pem)}"
    etcd_client_key  = "${base64encode(tls_private_key.client.private_key_pem)}"
  }
}

# Generated kubeconfig
resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "${var.asset_dir}/auth/kubeconfig"
}

# Generated kubeconfig with user-context
resource "local_file" "user-kubeconfig" {
  content  = "${data.template_file.user-kubeconfig.rendered}"
  filename = "${var.asset_dir}/auth/${var.cluster_name}-config"
}

resource "local_file" "admin-kubeconfig" {
  content  = "${data.template_file.admin-kubeconfig.rendered}"
  filename = "${var.asset_dir}/auth/admin-kubeconfig"
}


data "template_file" "kubeconfig" {
  template = "${file("${path.module}/resources/kubeconfig")}"

  vars {
    ca_cert      = "${base64encode(var.ca_certificate == "" ? join(" ", tls_self_signed_cert.kube-ca.*.cert_pem) : var.ca_certificate)}"
    kubelet_cert = "${base64encode(tls_locally_signed_cert.kubelet.cert_pem)}"
    kubelet_key  = "${base64encode(tls_private_key.kubelet.private_key_pem)}"
    user         = "kubelet"
    server       = "${format("https://%s:443", element(var.api_servers, 0))}"
  }
}

data "template_file" "user-kubeconfig" {
  template = "${file("${path.module}/resources/user-kubeconfig")}"

  vars {
    name         = "${var.cluster_name}"
    ca_cert      = "${base64encode(var.ca_certificate == "" ? join(" ", tls_self_signed_cert.kube-ca.*.cert_pem) : var.ca_certificate)}"
    kubelet_cert = "${base64encode(tls_locally_signed_cert.kubelet.cert_pem)}"
    kubelet_key  = "${base64encode(tls_private_key.kubelet.private_key_pem)}"
    server       = "${format("https://%s:443", element(var.api_servers, 0))}"
  }
}

data "template_file" "admin-kubeconfig" {
  template = "${file("${path.module}/resources/kubeconfig")}"
  vars {
    ca_cert      = "${base64encode(var.ca_certificate == "" ? join(" ", tls_self_signed_cert.kube-ca.*.cert_pem) : var.ca_certificate)}"
    kubelet_cert = "${base64encode(tls_locally_signed_cert.admin.cert_pem)}"
    kubelet_key  = "${base64encode(tls_private_key.admin.private_key_pem)}"
    server       = "${format("https://%s:443", element(var.api_servers, 0))}"
    user         = "admin"
  }
}


data "template_file" "controller-kubeconfig" {
  template = "${file("${path.module}/resources/kubeconfig")}"
  vars {
    ca_cert      = "${base64encode(var.ca_certificate == "" ? join(" ", tls_self_signed_cert.kube-ca.*.cert_pem) : var.ca_certificate)}"
    kubelet_cert = "${base64encode(tls_locally_signed_cert.controller.cert_pem)}"
    kubelet_key  = "${base64encode(tls_private_key.controller.private_key_pem)}"
    server       = "${format("https://%s:443", element(var.api_servers, 0))}"
    user         = "controller"
  }
}

data "template_file" "scheduler-kubeconfig" {
  template = "${file("${path.module}/resources/kubeconfig")}"
  vars {
    ca_cert      = "${base64encode(var.ca_certificate == "" ? join(" ", tls_self_signed_cert.kube-ca.*.cert_pem) : var.ca_certificate)}"
    kubelet_cert = "${base64encode(tls_locally_signed_cert.scheduler.cert_pem)}"
    kubelet_key  = "${base64encode(tls_private_key.scheduler.private_key_pem)}"
    server       = "${format("https://%s:443", element(var.api_servers, 0))}"
    user         = "scheduler"
  }
}
