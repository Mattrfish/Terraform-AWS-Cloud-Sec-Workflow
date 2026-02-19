# 1. The Identity Provider
resource "aws_iam_openid_connect_provider" "aws_oidc"{ # tells aws that github is a valid ID card issuer.
    url = "https://token.actions.githubusercontent.com" #The issuer of the OIDC token

    client_id_list = ["sts.amazonaws.com"] # the audiences that identifies the registered OIDC app

    thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # crypto signature of github
}

# 2. The Trust Policy
data "aws_iam_policy_document" "aws_oidc_trust_policy" { # only allow my specific Github repo to ask for credentials
    statement{
        sid = "1"

        actions = [ # what is allowed to happen?
            "sts:AssumeRoleWithWebIdentity" #specific to OIDC
        ]

        principals { # who is asking for access?
            type        = "Federated"
            identifiers = [aws_iam_openid_connect_provider.aws_oidc.arn]
        }

        condition {  # OAC security lock
                test = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values   = ["repo:Mattrfish/Terraform-AWS-Cloud-Sec-Workflow:*"]

        }

    }

}

# 3. The IAM Role
resource "aws_iam_role" "aws_oidc_role"{ # The actual "Ghost User" that GitHub will temporarily become.
    name = "github_actions_portfolio_role"
    assume_role_policy = data.aws_iam_policy_document.aws_oidc_trust_policy.json # attches the previousily made policy

}

# 4. The Permissions
resource "aws_iam_role_policy" "aws_oidc_role_policy"{ # Gives the "ghost user" permissions to upload files to the S3 bucket.
    name = "github_s3_deploy_policy"
    role = aws_iam_role.aws_oidc_role.id

    policy = jsonencode ({
        Version = "2012-10-17"
        Statement = [
            {
                Effect   = "Allow"
                Action   = [
                    "s3:PutObject",
                    "s3:ListBucket",
                    "s3:DeleteObject"
                ]
                
                Resource = [
                    module.secure_website_bucket.bucket_arn,
                    "${module.secure_website_bucket.bucket_arn}/*"
                ]
            }
        ]
        

    })
}

