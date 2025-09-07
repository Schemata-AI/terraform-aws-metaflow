
output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "UI ALB DNS name"
}

output "alb_arn" {
  value       = aws_lb.this.arn
  description = "UI ALB ARN"
}

output "alb_zone_id" {
  value       = aws_lb.this.zone_id
  description = "UI ALB Zone ID"
}
