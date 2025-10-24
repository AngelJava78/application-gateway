variable "project" {
  default     = "cfw"
  description = "Short name of the project or system to which the deployed resources belong."
}

variable "environment" {
  default     = "dev"
  description = "Defines the deployment environment. Possible values include: 'dev', 'qa', and 'prod'."
}

variable "region" {
  default     = "mex"
  description = "Variable for Azure resources location"
}

variable "location" {
  default     = "mexicocentral"
  description = "Variable for Azure resources location"
}

variable "address_space" {
  default     = "10.70.0.0/16"
  description = "Address space for virtual network"
}

variable "tags" {
  type        = map(string)
  description = "Custom map of tags to assign to resources. These can override the default tags if needed."
  default = {
    CreatedBy   = "Angel Valdez"
    Environment = "Dev"
  ProjectName = "Monitor Plus V5" }
}

variable "backend_address_pool_name" {
  default = "myBackendPool"
}

variable "frontend_port_name" {
  default = "myFrontendPort"
}

variable "frontend_ip_configuration_name" {
  default = "myAGIPConfig"
}
variable "vmSize_01" {
  default = "Standard_D2s_v3"
}

variable "vmSize_02" {
  default = "Standard_B2ms"
}


variable "http_setting_name" {
  default = "myHTTPsetting"
}

variable "listener_name" {
  default = "myListener"
}

variable "request_routing_rule_name" {
  default = "myRoutingRule"
}
