terraform {
  backend "s3" {
    bucket = "fluxcd-bucket-poc"
    key    = "poc/fluxcd/"
    region = "us-east-1"
  }
}
