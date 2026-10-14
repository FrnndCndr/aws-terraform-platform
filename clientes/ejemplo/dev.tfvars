client      = "ejemplo"
environment = "dev"
aws_profile = "ejemplo-dev"

vpc_cidr = "10.20.0.0/16"

site_force_destroy = true

backend_image                  = "public.ecr.aws/nginx/nginx:stable"
backend_container_port         = 80
backend_enable_execute_command = true
ecr_force_delete               = true

db_deletion_protection = false
db_skip_final_snapshot = true
db_apply_immediately   = true

uploads_force_destroy = true
