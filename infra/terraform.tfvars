
aws_region          = "us-east-1"
tf_state_bucket     = "lightfeather-s3" 
tf_state_lock_table = "lightfeather-locks" 

// Ensure these are your actual public subnet IDs from VPC vpc-07255e0202157ef09
// and that they are in different Availability Zones.
public_subnets      = [
  "subnet-05143a0450933f767", # us-east-1a
  "subnet-0c283c5c3e6921f45", # us-east-1d
  "subnet-0f2d50908500732a1", # Public subnet in the AZ of this subnet
  "subnet-0549e0adeb52793d8", # Public subnet in the AZ of this subnet
  "subnet-05f5bbdc0b165003e", # Public subnet in the AZ of this subnet
  "subnet-06f8bf47e4ac13ccc"  # Public subnet in the AZ of this subnet
]
