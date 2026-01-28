output "amazon_linux_2023_id" {
  description = "Latest Amazon Linux 2023 AMI ID"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "amazon_linux_2023" {
  description = "Full Amazon Linux 2023 AMI details"
  value = {
    id               = data.aws_ami.amazon_linux_2023.id
    name             = data.aws_ami.amazon_linux_2023.name
    creation_date    = data.aws_ami.amazon_linux_2023.creation_date
    architecture     = data.aws_ami.amazon_linux_2023.architecture
    root_device_type = data.aws_ami.amazon_linux_2023.root_device_type
  }
}

output "amazon_linux_2_id" {
  description = "Latest Amazon Linux 2 AMI ID"
  value       = data.aws_ami.amazon_linux_2.id
}

output "amazon_linux_2" {
  description = "Full Amazon Linux 2 AMI details"
  value = {
    id               = data.aws_ami.amazon_linux_2.id
    name             = data.aws_ami.amazon_linux_2.name
    creation_date    = data.aws_ami.amazon_linux_2.creation_date
    architecture     = data.aws_ami.amazon_linux_2.architecture
    root_device_type = data.aws_ami.amazon_linux_2.root_device_type
  }
}

output "ubuntu_22_04_id" {
  description = "Latest Ubuntu 22.04 LTS AMI ID"
  value       = data.aws_ami.ubuntu_22_04.id
}

output "ubuntu_22_04" {
  description = "Full Ubuntu 22.04 LTS AMI details"
  value = {
    id               = data.aws_ami.ubuntu_22_04.id
    name             = data.aws_ami.ubuntu_22_04.name
    creation_date    = data.aws_ami.ubuntu_22_04.creation_date
    architecture     = data.aws_ami.ubuntu_22_04.architecture
    root_device_type = data.aws_ami.ubuntu_22_04.root_device_type
  }
}

output "ubuntu_24_04_id" {
  description = "Latest Ubuntu 24.04 LTS AMI ID"
  value       = data.aws_ami.ubuntu_24_04.id
}

output "ubuntu_24_04" {
  description = "Full Ubuntu 24.04 LTS AMI details"
  value = {
    id               = data.aws_ami.ubuntu_24_04.id
    name             = data.aws_ami.ubuntu_24_04.name
    creation_date    = data.aws_ami.ubuntu_24_04.creation_date
    architecture     = data.aws_ami.ubuntu_24_04.architecture
    root_device_type = data.aws_ami.ubuntu_24_04.root_device_type
  }
}

output "windows_server_2022_id" {
  description = "Latest Windows Server 2022 AMI ID"
  value       = data.aws_ami.windows_server_2022.id
}

output "windows_server_2022" {
  description = "Full Windows Server 2022 AMI details"
  value = {
    id               = data.aws_ami.windows_server_2022.id
    name             = data.aws_ami.windows_server_2022.name
    creation_date    = data.aws_ami.windows_server_2022.creation_date
    architecture     = data.aws_ami.windows_server_2022.architecture
    root_device_type = data.aws_ami.windows_server_2022.root_device_type
  }
}

output "windows_server_2019_id" {
  description = "Latest Windows Server 2019 AMI ID"
  value       = data.aws_ami.windows_server_2019.id
}

output "windows_server_2019" {
  description = "Full Windows Server 2019 AMI details"
  value = {
    id               = data.aws_ami.windows_server_2019.id
    name             = data.aws_ami.windows_server_2019.name
    creation_date    = data.aws_ami.windows_server_2019.creation_date
    architecture     = data.aws_ami.windows_server_2019.architecture
    root_device_type = data.aws_ami.windows_server_2019.root_device_type
  }
}

output "kali_linux_id" {
  description = "Latest Kali Linux AMI ID"
  value       = data.aws_ami.kali_linux.id
}

output "kali_linux" {
  description = "Full Kali Linux AMI details"
  value = {
    id               = data.aws_ami.kali_linux.id
    name             = data.aws_ami.kali_linux.name
    creation_date    = data.aws_ami.kali_linux.creation_date
    architecture     = data.aws_ami.kali_linux.architecture
    root_device_type = data.aws_ami.kali_linux.root_device_type
  }
}