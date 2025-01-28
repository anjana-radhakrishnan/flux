terraform {
  backend "s3" {
    bucket         = "fluxcd-bucket-poc"     # Update it 
    key            = "poc" # Update it
    region         = "us-east-1"                            # Update it
    encrypt        = true
  }

