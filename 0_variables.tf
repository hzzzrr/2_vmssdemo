# 创建一个配置数据，定一个region列表，每个region对应不同的参数配置，比如vnet地址空间网段
variable "primary_region" {
  description = "Primary region"
  type        = string
  #default     = "southeastasia"
}


#input sub id for prod
variable "subscription-id" {
  type = string
  default = "db45786e-95f0-4c2d-8713-5385062aa342"  # ms subs
}
