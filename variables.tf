variable "autoscaling" {
  description = "Autoscaling"
  type        = any
  default     = null
}

variable "backup" {
  description = "Backup"
  type        = any
  default     = null
}

variable "ca_cert_identifier" {
  description = "The identifier of the CA certificate for the DB instances"
  type        = string
  default     = "rds-ca-2019"
}

variable "cloudwatch" {
  description = "Cloudwatch"
  type        = any
  default     = null
}

variable "credentials" {
  description = "Credentials"
  type        = any
  default     = null
}

variable "db_name" {
  description = "Database Name"
  type        = string
  default     = null
}

variable "db_subnet_group_name" {
  description = "Database Subnet Group Name"
  type        = string
  default     = ""
}

variable "encryption" {
  description = "Encryption"
  type        = any
  default     = null
}

variable "engine" {
  description = "Engine"
  type        = string
  default     = null
}

variable "engine_version" {
  description = "Engine Version"
  type        = string
  default     = null
}

variable "identifier" {
  description = "Identifier"
  type        = string
  default     = null
}

variable "instance" {
  description = "Instance"
  type        = any
  default     = null
}

variable "license_model" {
  description = "License Model"
  type        = string
  default     = null
}

variable "maintenance" {
  description = "Maintenance"
  type        = any
  default     = null
}

variable "monitoring_interval" {
  description = "Monitoring Interval"
  type        = number
  default     = 0
}

variable "multi_az" {
  description = "Enable MultiAZ"
  type        = bool
  default     = false
}

variable "nchar_character_set_name" {
  description = "NCHAR Character Set Name (Oracle)"
  type        = string
  default     = null
}

variable "option_group_name" {
  description = "Option group to use for instances"
  type        = string
  default     = null
}

variable "parameter_group_name" {
  description = "Parameter group to use for instances"
  type        = string
  default     = null
}

variable "performance_insights" {
  description = "Performance Insights"
  type        = any
  default     = null
}

variable "port" {
  description = "Port"
  type        = number
  default     = null
}

variable "replica" {
  description = "Replica"
  type        = any
  default     = null
}

variable "security_groups_additional" {
  description = "Security Groups (Additional)"
  type        = list(any)
  default     = []
}

variable "security_group_rules" {
  description = "Security Group Rules"
  type        = any
  default     = null
}

variable "snapshot_identifier" {
  description = "Database Snapshot ARN to create this database from"
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Timeouts"
  type        = any
  default = {
    create = "180m"
    delete = "120m"
    update = "120m"
  }
}

variable "vpc_id" {
  description = "VPC: ID"
  type        = string
  default     = ""
  validation {
    condition     = var.vpc_id != ""
    error_message = "VPC ID not Specified."
  }
}
