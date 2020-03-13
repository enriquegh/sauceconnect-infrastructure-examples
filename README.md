# Sauce Connect Terraform Infrastructure Examples

This repository attempts to mimic a customer environment with locked down machines and select traffic coming in and out of the box.

## Set up
You will need:
- AWS Credentials
- AWS KeyPair that will be used on EC2 instances and will allow you to SSH into them.

For now, the easiest will be to have admin access or anything close to it since multiple things are being touched/used.

- Terraform 0.12

Can be installed [here](https://www.terraform.io/downloads.html).


## Running

1. Make sure your AWS credentials are stored in `~/.aws/credentials`

It should look something like:
```
[default]
aws_access_key_id = XXXXXXXX
aws_secret_access_key = XXXXXXXXX
```
For more info on the credentials file see [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

2. Initialize Terraform

On the root directory of the repository, run:
```bash
terraform init
```

3. Plan and Apply changes

Once ready you can see/plan the changes that will be done with:
```bash
terraform plan
```
It will ask you for the path of your SSH key locally on your machine as well as the name of the AWS KeyPair
You can also do:
```bash
terraform plan -var key_name=[AWS_KEYPAIR_NAME] -var key_path=[AWS_SSH_KEY_PATH]
```

Once changes look good you can run this with:
```bash
terraform apply
```
or like before, something like:
```bash
terraform apply -var key_name=[AWS_KEYPAIR_NAME] -var key_path=[AWS_SSH_KEY_PATH]
```

You should see at the end something like:
```
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

proxy_private_ip = 10.0.0.59
proxy_public_ip = 44.234.49.91
sc_app_private_ip = 10.0.1.159
```

## Simple Proxy & SC set up

The current set up involves a VPC with two subnets.

One public subnet has direct access to the internet.
Here runs a machine with Squid proxy on it.

One private subnet with no internet access and only access to internal traffic within the VPC.
Here runs a machine with latest Sauce Connect binaries installed.

The exercise here is the private machine is completely blocked off the internet and needs traffic to go through the proxy.

### Output Values
This plan contains the following output values:
```
proxy_public_ip - Public IP Address of the instance running Squid

proxy_private_ip - Private IP Address of the instance running Squid

sc_app_private_ip - Private IP Address of the instance running Sauce Connect

```

### SSH into machines

To SSH into the instance on the public subnet run:
```bash
ssh -i [AWS_SSH_KEY_PATH] ubuntu@proxy_public_ip
```

To SSH into the instance on the public subnet run:
```bash
ssh -i [AWS_SSH_KEY_PATH] -J ubuntu@proxy_public_ip ubuntu@sc_app_private_ip
```
to use the public instance and proxy jump to the correct host.

### Run Sauce Connect
To run Sauce Connect, you will have to use the private IP of our proxy host and send all traffic through it.
By default Squid is listening on port 3128.

This means your command will look something like:

```bash
./bin/sc -p proxy_private_ip:3128 -T
```