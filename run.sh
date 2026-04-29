echo "initialization"
terraform init -upgrade
echo "validation"
terraform validate
echo "planning"
terraform plan
echo "applying"
terraform apply --auto-approve