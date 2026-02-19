module "secure_website_bucket" {
    source      = "./modules/s3-bucket"
    bucket_name = "terraform-portfolio-project-2026"

}

module "secure_cdn" {
    source = "./modules/cloudfront"
    origin_id          = module.secure_website_bucket.bucket_id
    bucket_domain_name = module.secure_website_bucket.bucket_regional_domain_name
}


# set the S3 bucket policy for cloud front to access
data "aws_iam_policy_document" "S3_policy"{

    statement{
        sid = "1"

        actions = [ # what is allowed to happen?
            "s3:GetObject" #lets cloudfront access the bucket
        ]

        resources = [ # what is being accessed?
            "${module.secure_website_bucket.bucket_arn}/*", # applies to all files inside

        ]

        principals { # who is asking for access?
            type        = "Service"
            identifiers = ["cloudfront.amazonaws.com"]

        }

        condition { # OAC security lock
            test     = "StringEquals"
            values   = [module.secure_cdn.cloudfront_arn]
            variable = "AWS:SourceArn"

        }

    }
}

resource "aws_s3_bucket_policy" "cdn_oac_policy"{ # glues the iam policy to the bucket
    bucket = module.secure_website_bucket.bucket_id # bucket id from output
    policy = data.aws_iam_policy_document.S3_policy.json # json output of the s3 iam policy above

}