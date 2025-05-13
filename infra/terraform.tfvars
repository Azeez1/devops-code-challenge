
aws_region          = "us-east-1"
tf_state_bucket     = "YOUR_ACTUAL_S3_BUCKET_NAME" 
tf_state_lock_table = "YOUR_ACTUAL_DYNAMODB_TABLE_NAME" 

// Ensure these are your actual public subnet IDs from VPC vpc-07255e0202157ef09
// and that they are in different Availability Zones.
public_subnets      = ["subnet-05143a0450933f767", "subnet-0c283c5c3e6921f45"]
