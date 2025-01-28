terraform {
  backend "s3" {
    bucket         = "fluxcd-bucket-poc"    
    key            = "poc" # Update it
    region         = "us-east-1"                          
    encrypt        = true
  }
}

