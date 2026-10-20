environment = "dev"
aws_profile = "ejemplo-dev"

vpc_cidr = "10.20.0.0/16"

backend_image          = "public.ecr.aws/nginx/nginx:stable"
backend_container_port = 80

github_owner               = "ejemplo-org"
github_backend_repository  = "ejemplo-api"
github_frontend_repository = "ejemplo-web"
