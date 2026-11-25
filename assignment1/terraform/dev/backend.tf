terraform {
  backend "s3" {
    bucket       = "acs730-tfstate-232620255552"
    key          = "assignment1/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

