# Resource Group
# https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftresources
# Length: 1-90 characters
# Valid Characters: Underscores, hyphens, periods, parentheses, and letters or digits as defined by the Char.IsLetterOrDigit function.
# Valid characters are members of the following categories in UnicodeCategory: UppercaseLetter, LowercaseLetter,TitlecaseLetter, ModifierLetter, OtherLetter, DecimalDigitNumber
# Can't end with period.
module "resource_group_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.25.0"
  namespace  = var.label_namespace
  stage      = var.label_stage
  name       = var.label_name
  attributes = ["rg"]
  delimiter  = "-"
  tags       = var.default_tags
  enabled    = var.resource_group_name == "" ? true : false
}

# Key Vault
# https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftkeyvault
# Length: 3-24 characters
# Valid charachters: Alphanumerics and hyphens. Start with letter. End with letter or digit. Can't contain consecutive hyphens.
module "key_vault_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.25.0"
  namespace  = var.label_namespace
  stage      = var.label_stage
  name       = var.label_name
  attributes = ["kv"]
  delimiter  = "-"
  tags       = var.default_tags
  enabled    = true
}