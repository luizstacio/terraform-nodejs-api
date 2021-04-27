Enviornoment variables required

|Name|Type|Example|
|-|-|-|
|AWS_ACCESS_KEY|string|""
|AWS_SECRET_KEY|string|""
|AWS_REGION|string|"sa-east-1"
|TF_VAR_app|string|"sampleapi"
|TF_VAR_tags|oject|'{"Terraform":true,"Cliente":"******"}'
|TF_VAR_private_subnets|string|"subnet-******,subnet-******,subnet-******"
|TF_VAR_port|string[]|80
|TF_VAR_protocol|string|HTTP
|TF_VAR_vpc_id|string|"vpc-********"
|TF_VAR_container_port|number|80
|TF_VAR_lb_port|number|80
|TF_VAR_lb_protocol|string|TCP
|TF_VAR_region|string|$AWS_REGION
|TF_VAR_bucket|string|******
|TF_VAR_db_instance|string|db.t2.micro
|TF_VAR_db_name|string|sampledatabaseapi