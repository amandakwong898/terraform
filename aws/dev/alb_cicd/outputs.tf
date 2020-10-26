output "alb_cicd_arn" {
  value = "${module.alb_cicd.alb_cicd_arn}"
}

output "jenkins_tg_arn" {
  value = "${module.alb_cicd.jenkins_tg_arn}"
}

output "nexus_tg_arn" {
  value = "${module.alb_cicd.nexus_tg_arn}"
}

output "sonarqube_tg_arn" {
  value = "${module.alb_cicd.sonarqube_tg_arn}"
}
