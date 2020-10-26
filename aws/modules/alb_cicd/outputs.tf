output "alb_cicd_arn" {
  value = aws_lb.cicd.arn
}

output "jenkins_tg_arn" {
  value = aws_lb_target_group.jenkins_tg.arn
}

output "nexus_tg_arn" {
  value = aws_lb_target_group.nexus_tg.arn
}

output "sonarqube_tg_arn" {
  value = aws_lb_target_group.sonarqube_tg.arn
}
