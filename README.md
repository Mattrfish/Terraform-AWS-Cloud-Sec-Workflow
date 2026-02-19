# Terraform-AWS-Cloud-Sec-Workflow

This project demonstrates a security-first Infrastructure as Code (IaC) workflow using Terraform to provision and secure AWS infrastructure following cloud security best practices.

---

### Installation

#### Chocolatey

"Chocolatey is a free, open-source command-line package manager for Windows that automates the installation, upgrading, and configuration of software. It acts as a wrapper around existing installers, utilizing NuGet and PowerShell to simplify managing software, often acting as the Windows equivalent to Linux's apt-get."

` Set-ExecutionPolicy Bypass -Scope Process -Force; \\\[System.Net.ServicePointManager]::SecurityProtocol = \\\[System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) `

#### Terraform 

"Terraform is an open-source "Infrastructure as Code" (IaC) tool created by HashiCorp that enables users to define, provision, and manage cloud and on-premises infrastructure using human-readable configuration files. It uses a declarative approach, allowing users to describe the desired end state, while Terraform handles the API calls to build it."

` choco install terraform -y `

#### AWS-CLI

"The AWS Command Line Interface (AWS CLI) is an open-source tool from Amazon Web Services that allows users to interact with AWS services directly from the command line. It acts as a unified, text-based interface that enables developers, system administrators, and DevOps professionals to manage, configure, and automate AWS resources—such as EC2 instances or S3 buckets—using commands in their terminal (Linux/macOS) or command prompt/PowerShell (Windows)."

` msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi `

```bash
 PS C:\\WINDOWS\\system32> aws --version 
aws-cli/2.33.25 Python/3.13.11 Windows/11 exe/AMD64  
```

---

### AWS Configuration 

#### IAM User

"AWS Identity and Access Management (IAM) is a free, core web service for securely controlling access to AWS resources. It enables centralized management of users, groups, and roles, using JSON-based policies to define permissions (allow/deny) for actions, following the principle of least privilege. Key features include multi-factor authentication (MFA) and integration with existing corporate directories."

As it is bad practice to use a root account for terraform, I have created an IAM user account for this function and attached the admin access policy to it. 

Ive created access keys with this account for better security and to access the aws console from cli.

` aws configure  (Enter credentials to access aws console) `
` aws sts get-caller-identity (Verify access) `

---

### Initialise the Project

Firstly, I have setup this GitHub repo and set the project folder structure.

Next, I have configured the foundation files so that terraform can start working:

* **providers.tf** : This tells terraform the aws region that I am using, which in my case is eu-west-2.

* **.gitignore** : I have used the pre-configured terraform template to ensure that I don't upload any secret keys to GitHub. 

Now that the structure exists and the provider is defined, I will initialise terraform:

```bash
terraform init 
"Terraform has been successfully initialized!" 
```

This confirms the folder structure is valid and my connection to AWS is working.

---

### Build the S3 Bucket Module

To start the project I need to create an S3 bucket module which is a pre-configured, reusable terraform script which will allow me to manage the bucket with best practices (encryption, versioning, logging, and access policies).

#### Input

I have created a variable block under modules/s3-bucket/variables.tf which will name, describe the bucket and set its type (eg string). 

```bash
variable "bucket_name" { 
    description = "Name of the S3 bucket"
    type        =  string
}
```

#### Logic

The logic part uses `modules/s3-bucket/main.tf` to define 4 resources. These resources are:

* **Bucket**: This creates the actual storage container. [1]
* **Security**: Acts as a firewall around the bucket to prevent accidental public exposure. [2]
* **Versioning**: Creates a backup of every file change. [3] 
* **Encryption**: Makes the data unreadable without a key. [4]

![The full logic code deifining all 4 resources.](images/img-1.png)


#### Output

Once the bucket has been built by terraform, it needs to tell us the Bucket ARN (Amazon Resource Name) to use later for the CloudFront permission policy.

![The output block](images/img-2.png)

#### Running the Module

The module needs to be run by calling it from the root `main.tf` file:

![The root .tf file that calls the bucket](images/img-3.png)

` terraform init (This prepares the new module)` 
` terraform plan (This checks for errors)`

After running it i realised i had a few spelling errors to be correct. Now time to see if it has worked...

```bash
terraform plan
╷
│ Error: Missing required argument
│
│   on main.tf line 1, in module "secure_website_bucket":
│    1: module "secure_website_bucket" {
│
│ The argument "first_bucket" is required, but no definition was found.
╵
╷
│ Error: Unsupported argument
│
│   on main.tf line 3, in module "secure_website_bucket":
│    3:     bucket_name = "terraform-portfolio-project-2026"
│
│ An argument named "bucket_name" is not expected here.
╵
```

Not quite what i was expecting but after a quick troubleshoot i realised i didnt match the variable name to the one in main. 

Beginners error.

Time to try again...

..... And it got added to the plan.

Adding it to a plan first is very useful as in the DevSecOps workflow, integrating security into the pipeline ensures that there are no issues when deploying instead of waiting until the end. This means that i can now work on the cloudfront module and deploy it all together.

---

### Build the CloudFront Module

 Next i built a cloudfront module that sits in front of the bucket. It is a fast, secure content delivery network (CDN) service that accelerates the delivery of websites, APIs, and video content globally by caching content at edge locations close to users. It reduces latency, improves speed, increases reliability and integrates with AWS services (S3, EC2, ELB). It includes security features like DDoS protection (AWS Shield) and custom SSL.

 The goal is to ensure HTTPS traffic only and OAC (Origin Access Control) which is the modern way to authenticate CloudFront to S3 ensuring that only my CloudFront distribution can read my bucket.

 #### Input

 I set some cloufront variables:
 
 * **origin_id:**: This sets the ID of the S3 bucket for reference. 
 * **bucket_domain_name** : This sets the domain name of the S3 bucket.

![Variables usesd for the CloudFront module](images/img-5.png)

 
 #### Logic

 CloudFront can't work alone; it needs to know which bucket to talk to. This means the information from my S3 module needs to be passed into this CloudFront module.

 * **Origin Access Control**: This choose which origins can be accessed (e.g s3 bucket)
 * **Distribution**: This is where all of the behviours are specified (e.g origin, cache behaviour, restrictions and viewer certificate) [5]

![The full logic code defining the cloudfront module](images/img-4.png)

#### Output

The cloudfront module will output its domain name and its ID into the outputs folder, which can be used to access in other modules.

![alt text](images/img-6.png)

---

### Deploy to AWS

` terraform apply `

With the apply, the current S3 bucket has got an access policy on it, only allowing myself and AWS to talk to it, meaning that cloudfront cannot access it. So actually before i deploy, I will up the S3 buckett policy first to allow it access.

---

### S3 Bucket and IAM Policy

First, S3 needs to know the cloudfront amazon resource name (ARN). I have gathered this from setting it within the cloudfront modules outputs:

```bash
output "cloudfront_arn" {
  value       = aws_cloudfront_distribution.s3_distribution.arn
  description = "The ARN of the cloudfront distribution"
}
```

To pass this into the S3 bucket, i will create some policies in the root main.tf folder. 

Ill create an IAM policy to determine what is being accessed and by whom. Insidse this contains a statement. The statement contains blocks and maps. These are: [6]

* **actions**: Describes the actions that are allowed to happen (e.g access the s3 bucket)
* **resources**: Describes what is being accessed (my exact bucket that i want cloudfront to access)
* **principals**: Describes who asking for access to the resource (in my case cloudfront)
* **condition**: Based upon the condition, a security lock for specific access to the resource (only my secure cloudfront module)

![The IAM policy for secure cloudfront access]!(images/img-7.png)

Currently AWS doesnt know what to do with the IAM policy. The last thing to do is to create an S3 bucket policy which will glue the IAM polciy to the S3 bucket. [7] 

```bash

resource "aws_s3_bucket_policy" "cdn_oac_policy"{ # glues the iam policy to the bucket
    bucket = module.secure_website_bucket.bucket_id # bucket id from output
    policy = data.aws_iam_policy_document.S3_policy.json # json output of the s3 iam policy above

}

```
Now its time to officially apply the changes:

`Apply complete! Resources: 7 added, 0 changed, 0 destroyed.`

I got the websitee url is an output and when i visited it i got access denied. This is a good sign to show that the polices are working. Currently only cloudfront can access it, however it does not contain any resources yet.

![Access denied to thee hosted s3 bucket](images/img-8.png)

---

#### Adding the Content

Next i will add the content to the bucket so that cloudfront actaully has something to serve. 

### Quick Cloudfront config

Before any files are uploaded, cloudfront needs to know which file is the homepage. Currently it doesnt know whether to server the index.html, about.html or an image.

I need to define the default root object within the main cloudfront module:

`default_root_object = "index.html"`

I will run terraform apply to update these changes.

### Creating the Website

Ill create a new file called index.html which will be the homepage for my test website. I will use just some basic html defining a title, heading, pararaphs and the style.

![The index.html file](images/img-9.png)

### Upload to the S3 Vault

In a real DecSecOps scenario, a CI/Cd pipeline would automate the upload of the code. An example of this is github actions. "GitHub Actions is a continuous integration and continuous delivery (CI/CD) platform that allows you to automate your build, test, and deployment pipeline. You can create workflows that build and test every pull request to your repository, or deploy merged pull requests to production."

For this scenario i couold just run this command...

`aws s3 cp index.html s3://MY_BUCKET_NAME/` 

... and act as the pipeline to directly upload to the bucket.

But I will follow the standard of using the CI/CD pipeline to automate it, as it can allow me to updat e the file adn use version control if i make any errors.

I will be using github actions to do this.

### Github Actions

I need to let github talk to AWS by giving it an ID card. This can be done through generating an IAM using with a permanant key or using OpenID Connect (the main standard) which will let github generate me a temporary token from aws which will expire. 

I have already created keys for an IAM user to use this CLI so that i am not using root. I will choose the OIDC for this situation. 

OIDC is better and used as the standard becauase it follows the principle of least privilege and eliminates long-term credential risk.


### OPenID Connect Setup

Ill create a new file called oidc.tf to put all of the config in and keep it organised. It will contain four blocks: [9]

* **iam openid provider**: Provides the ulr for issuing the token, the thumbprint list for github and the client id list. [8] [10] [11]
* **iam policy document**: Specified to only allows my specific Github repo to ask for credentials
* **iam role**: This sets github as a temporary "ghost user". [12]
* **iam role polciy**: Gives the "ghost user" permissions to upload files to the S3 bucket. [13]

An output was also added to get the ARN of the role.

As you notice there is a trend. Whenever a resource is created. For instead the iam role, there is a policy document that follows it, which ensures security is added throughout following teh DevSecOps cycle.

![The OIDC config](images/img-10.png)

---

### The DevSecOps Pipeline

Now that the homepage is built and the OpenID has been configured, Github needs to be told how to talk to AWS, take the "ghost role" and upload the website files automatically everytime i push code.

From my perspective, it seems similiar to netlify. As you push chode, netlify will deploy the changes to the websitehosted on your domain.

Anyways back to configuring github actions.

#### Github Actions Configuration

Even though ARN isnt a secret password, its still better not to hardcode ifrastructure details into the pipeline. 

I have created a repo secret which contains the ARN from role and the S3 bucket. 

Next ill create the workflow file: `.gtihub/workflows/deploy.yml`

Here i will write the pipeline. [14]

For this pipeline i have told it to deploy on the main branch, given it permissions to write the id tokens and read the contents and also run a job. The job runs on ubuntu and follows these steps:

* **1**: Checkouts the Code.
* **2**: Conifgures the AWS credentials using the Role ARN.
* **3**: Syncs the files to the S3 Bucket.

![YMl workflow to deploy the website to AWS](images/img-11.png)

#### Launching the Website

Now it is time to deploy the website. 

Ill run the add, commit and push commands to deploy to github and let github automate the deploy to the S3 bucket. 

```bash
git add .
git commit -m "Add OIDC trust and CI/CD pipeline"
git push
```
After pushing, straight away it declined due to repo rule violations. This is the secret scanning push protection in action. It found the keys stored in .env and stopped to protect it from being exposed. 

I thought i had already included it in gitingore but apparently not sure thats why these features are always valuable to use.



### References

[1]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
[2]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
[3]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
[4]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
[5]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
[6]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
[7]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
[8]: https://docs.github.com/en/actions/reference/security/oidc
[9]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider.html
[10]: https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
[11]: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws
[12]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
[13]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy
[14]: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#on






