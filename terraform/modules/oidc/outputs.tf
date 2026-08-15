output "provider_arn" {
  value = aws_iam_openid_connect_provider.cluster.arn
}

output "provider_url" {
  value = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
}
