terraform {
  backend "s3" {
    bucket         = fluxcd-bucket-poc       # Replace with your S3 bucket name
    region         = us-east-1              # Replace with your AWS region
    encrypt        = true
  }
}
