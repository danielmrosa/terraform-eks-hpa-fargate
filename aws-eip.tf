resource "aws_eip" "eip" {
  count = length(aws_subnet.aws-subnets-public.*.id)
  vpc   = true
   

  depends_on = [data.aws_subnet_ids.subnet-ids-public]
}