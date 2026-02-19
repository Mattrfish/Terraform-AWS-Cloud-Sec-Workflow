# 1: Bucket
resource "aws_s3_bucket" "my_bucket"{
    bucket = var.bucket_name # name of the bucket var from var.tf

    force_destroy = true # deletes bucket (including files) upon deletion

}

# 2: Security
resource "aws_s3_bucket_public_access_block" "my_bucket_security" {
    bucket = aws_s3_bucket.my_bucket.id # link to previous resource

    block_public_acls        = true # PUT Bucket ACL will fail
    block_public_policy      = true # Reject calls to PUT Bucket policy
    ignore_public_acls       = true # Ignore public ACLs on this bucket and any objects that it contains.
    restrict_public_buckets  = true # Only the bucket owner and AWS Services can access this bucket.
}

# 3: Versioning 
resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
    bucket = aws_s3_bucket.my_bucket.id # link again

    versioning_configuration {
        status = "Enabled"
    }
}

# 4: Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket_encryption" {
    bucket = aws_s3_bucket.my_bucket.id # link again

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm     = "AES256" # algorithm to use.
                                         # also can use s3 kms to set keys
        }
    }
}