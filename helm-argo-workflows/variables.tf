variable "aws_region" {
  default = "eu-west-2"
}

variable "application_name" {
  type    = string
  default = "terramino"
}

variable "slack_app_token" {
  type        = string
  description = "Slack App Token"
}

variable "workflows_version" {
  type = string
  default = "0.11.2"
  description = "helm chart version of argo workflows"
}
