// delete previous dkim because I don't know how to handle the planning/applying phase difference.
resource "null_resource" "delete_previous_build_file" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "rm -f dkim_output.txt"
  }
}
