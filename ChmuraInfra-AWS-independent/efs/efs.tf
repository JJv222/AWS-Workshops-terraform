resource "aws_efs_file_system" "main" {
  creation_token = var.creation_token
  encrypted      = true
  tags           = {Name = var.creation_token}
}


resource "aws_efs_mount_target" "targets" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_groups
}


resource "aws_efs_access_point" "postgres" {
  file_system_id = aws_efs_file_system.main.id
  root_directory { 
    path = "/postgres" 
    creation_info { 
      owner_gid = 1000 
      owner_uid = 1000 
      permissions = "755" 
    } 
  }
}


resource "aws_efs_access_point" "grafana" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 472
    uid = 472 
  }

  root_directory {
    path = "/grafana-data"
    creation_info {
      owner_gid   = 472
      owner_uid   = 472
      permissions = "755"
    }
  }
}

resource "aws_efs_access_point" "minio" {
  file_system_id = aws_efs_file_system.main.id
  root_directory { 
    path = "/minio" 
    creation_info { 
      owner_gid = 1000 
      owner_uid = 1000 
      permissions = "755" 
    } 
  }
}

resource "aws_efs_access_point" "prometheus" {
  file_system_id = aws_efs_file_system.main.id
  
  posix_user {
    gid = 65534
    uid = 65534
  }

  root_directory { 
    path = "/prometheus" 
    creation_info { 
      owner_gid = 65534 
      owner_uid = 65534 
      permissions = "755" 
    } 
  }
}