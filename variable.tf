variable "rgname" {
  type        = string
  description = "Name of the Resource Group"
}

variable "location" {
  type        = string
  description = "Azure Region"
}

variable "workspace" {
  type        = string
  description = "Log Analytics Workspace name"
}

variable "prefix" {
  type        = string
  description = "Prefix for naming conventions"
}

variable "hostpool" {
  type        = string
  description = "Name of the AVD Host Pool"
}

variable "rfc3339" {
  type        = string
  description = "Registration token expiration in RFC3339 format"
}

variable "dag" {
  type        = string
  description = "Name of the Application Group"
}
