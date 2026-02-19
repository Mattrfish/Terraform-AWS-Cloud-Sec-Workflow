resource "aws_cloudfront_origin_access_control" "my_cdn" {
  name                              = "secure-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4" # cryptographically sign every request it makes to S3
}

resource "aws_cloudfront_distribution" "s3_distribution" { # the global network of servers
    enabled = true # Whether the distribution is enabled to accept end user requests for content.
    default_root_object = "index.html"

    origin{ # One or more origins for this distribution 
        domain_name              = var.bucket_domain_name
        origin_id                = var.origin_id
        origin_access_control_id = aws_cloudfront_origin_access_control.my_cdn.id
    }

    default_cache_behavior {
        allowed_methods = ["GET", "HEAD"] # Controls which HTTP methods CloudFront processes and forwards to Amazon S3 bucket or custom origin.
        cached_methods = ["GET", "HEAD"] # Controls whether CloudFront caches the response to requests using the specified HTTP methods.
        target_origin_id = var.origin_id # ID of the origin that CloudFront will route requests to

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }

        viewer_protocol_policy = "redirect-to-https" # specify the protocol that users can use to access the files in the origin 
    }

    restrictions { # The restriction configuration for this distribution
        geo_restriction {
        restriction_type = "none"
        }
    }

    viewer_certificate { # The SSL configuration for this distribution 
        cloudfront_default_certificate = true
    }
}