# AWS region
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

# ECS task memory (in MiB)
variable "memory" {
  description = "Amount of memory for the ECS task"
  type        = number
  default     = 512
}

# ECS task CPU (in units)
variable "cpu" {
  description = "Amount of CPU for the ECS task"
  type        = number
  default     = 256
}

# Port exposed by the Strapi container
variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 1337
}

# Full ECR image URI including tag (e.g., repo/image:tag)
variable "ecr_image_url" {
  description = "URI of the Docker image to deploy"
  type        = string
}
