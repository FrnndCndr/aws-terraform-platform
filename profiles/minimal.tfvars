az_count           = 2
enable_nat_gateway = false

backend_cpu                    = 256
backend_memory                 = 512
backend_desired_count          = 1
backend_enable_execute_command = true

db_instance_class           = "db.t4g.micro"
db_multi_az                 = false
db_max_allocated_storage_gb = null
db_backup_retention_days    = 7
db_deletion_protection      = false
db_skip_final_snapshot      = true
db_apply_immediately        = true

site_force_destroy    = true
uploads_versioning    = false
uploads_force_destroy = true

ecr_image_tag_mutability = "MUTABLE"
ecr_force_delete         = true

log_retention_days = 7

secrets_recovery_window_days = 0
