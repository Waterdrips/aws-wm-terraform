This is some rough example code that spins up a ECS Fargate service running nginx.

To run this yourself:

Change the backend config in main.tf to point to your backend type. (or remove the block if you want to use local state)

Install terraform 0.12.x

configure your aws credentials (see AWS docs)

if using ci, you will need to put your AWS credentials in the env variables. (And the tf_token if using terraform backend)




## To run locally
run `terraform init` - This should install the providers etc

run `terraform plan` - Make sure all the changes make sense and are what you expect

run `terrafrom apply` - When prompted, read the changes and if you want to apply them, follow the instructions on the command line

This should then create the infrastructure and output the dns name to the console. You can go to this in your browser and should see the
welcome to nginx banner


To remove your stack run `terraform destroy` and follow the onscreen instructions.


##To run this in CI
Theres some work you will have to do here - The current `bitbucket-pipelines.yml` will only work on bitbucket (duh!)

You will need to convert this into your preferred CI's config.

NOTE: THIS IS NOT PRODUCTION READY. 
