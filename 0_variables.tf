# 创建一个配置数据，定一个region列表，每个region对应不同的参数配置，比如vnet地址空间网段
variable "primary_region" {
  description = "Primary region"
  type        = string
  #default     = "southeastasia"
}


#input sub id for prod
variable "subscription-id" {
  type = string
  default = "ac48f6d7-7d46-45dc-90d5-c43d85721e6a"  #订阅ID
}
