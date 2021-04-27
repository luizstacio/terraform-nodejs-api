resource "local_file" "write_action" {
    content = templatefile("${path.module}/templates/aws.yml", {
        ecs_resposity_name = aws_ecr_repository.app.name,
        ecs_service_name = aws_ecs_cluster.app.name,
        ecs_cluster_name = aws_ecs_service.app.name,
        ecs_container_name = var.app
    })
    filename = "../.github/workflows/aws.yml"
}