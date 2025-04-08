output "n8n_fqdn_url" {
  description = "https url that contains ingress's fqdn, could be used to access the n8n app."
  value       = module.container_app.fqdn_url
}

output "openai_key_secret_url" {
  description = "https url that contains the openai key secret in the key vault."
  value       = module.key_vault.secrets["openai-key"].versionless_id
}

output "openai_endpoint" {
  description = "The endpoint of the OpenAI deployment."
  value       = module.openai.endpoint
}

output "openai_resource_name" {
  description = "The name of the OpenAI deployment."
  value       = module.openai.resource.custom_subdomain_name
}

output "openai_deployment_name" {
  description = "The name of the OpenAI deployment."
  value       = module.openai.resource_cognitive_deployment["gpt-4o-mini"].name
}

output "openai_api_version" {
  description = "The version of the OpenAI API to n8n credential. See https://learn.microsoft.com/en-us/azure/ai-services/openai/api-version-deprecation"
  value       = "2025-03-01-preview"
}

