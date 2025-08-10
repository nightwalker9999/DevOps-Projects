resource "aws_sns_topic" "sns_topic" {

  # created myself
  name = var.name #referring the vars tf
  tags = var.tags #referring the vars tf
}