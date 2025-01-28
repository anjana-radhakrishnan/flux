terraform {
  backend "s3" {
    bucket         = "fluxcd-bucket-poc"    
    region         = "us-east-1"                           
    encrypt        = true
  }
}

