output "zone_a_bastion" {
  value = "${module.zone_a.bastion_host}"
}

output "zone_b_bastion" {
  value = "${module.zone_b.bastion_host}"
}
