az_count           = 2
enable_nat_gateway = true
single_nat_gateway = true

backend_cpu                    = 256
backend_memory                 = 512
backend_desired_count          = 2
backend_enable_execute_command = false

db_instance_class           = "db.t4g.micro"
db_multi_az                 = true
db_max_allocated_storage_gb = 100
db_backup_retention_days    = 14
db_deletion_protection      = true
db_skip_final_snapshot      = false
db_apply_immediately        = false

site_force_destroy    = false
uploads_versioning    = true
uploads_force_destroy = false

ecr_image_tag_mutability = "IMMUTABLE"
ecr_force_delete         = false

log_retention_days = 30
