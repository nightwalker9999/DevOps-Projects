output "artifacts_bucket" { value = module.artifacts_bucket.bucket_id }
output "logs_bucket"      { value = module.logs_bucket.bucket_id }
output "queue_url"        { value = module.queue.queue_url }
output "dlq_url"          { value = module.queue.dlq_url }
