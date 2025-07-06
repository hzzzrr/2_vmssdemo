# create vmss user data using cloud-init
locals {
  vmss_user_data = templatefile("${path.module}/vmss-cloud-init.yaml", {})
}


# create vmss for using ubuntu image
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  depends_on = [ azurerm_lb_probe.http_probe_health ]
  
  name                = "vmss-vmss-demo"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.primary_region
  sku                 = "Standard_D2s_v3"
  instances           = 2

  admin_username      = "zhouruihan"

  admin_ssh_key {
    username   = "zhouruihan"
    public_key = file("C:/Users/zhouruihan/.ssh/id_rsa.pub")
    #to-do~
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  network_interface {
    name    = "vmss-nic"
    primary = true
    ip_configuration {
      name                          = "internal"
      primary                       = true
      subnet_id                     = azurerm_subnet.vm_subnet.id
      load_balancer_backend_address_pool_ids = [ azurerm_lb_backend_address_pool.backend_address_pool_vmss.id ]
      public_ip_address {
        name = "vmss-public-ip"
      }
    }
  }

  # az vm image list --all -l southeastasia --publisher Canonical
  source_image_reference {
    publisher = "Canonical" 
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  user_data = base64encode(local.vmss_user_data)

  zones = ["1", "2"]
  zone_balance = true

  # enable automatic instance repair after 10 minutes, using http probe /health
  health_probe_id = azurerm_lb_probe.http_probe_health.id
  upgrade_mode = "Automatic"
  automatic_instance_repair {
    enabled = true
    grace_period = "PT10M"
  }
  termination_notification {
    enabled = true
    timeout = "PT10M"  # 10分钟通知期（ISO 8601 持续时间格式）
  }
  scale_in {
    rule = "OldestVM"
    force_deletion_enabled = true
  }
}

# create vmss auto scale rule
resource "azurerm_monitor_autoscale_setting" "vmss_auto_scale" {
  name                = "vmss-auto-scale-vmss-demo"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.primary_region
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        # dimensions {
        #   name     = "AppName"
        #   operator = "Equals"
        #   values   = ["App1"]
        # }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"#v1.0
      }
    }
  }

  # predictive {
  #   scale_mode      = "Enabled"
  #   look_ahead_time = "PT5M"
  # }

  notification {
    email {
      # send_to_subscription_administrator    = true
      # send_to_subscription_co_administrator = true
      custom_emails                         = ["zhouruihan@microsoft.com"]
    }
  }
}

# 获取所有 VMSS 实例
data "azurerm_virtual_machine_scale_set" "vmss_vms" {
  name = azurerm_linux_virtual_machine_scale_set.vmss.name
  resource_group_name          = azurerm_resource_group.rg.name
}


# 输出
output "vm_names_and_public_ips" {
  value = [
    for vm in data.azurerm_virtual_machine_scale_set.vmss_vms.instances :
    "${vm.computer_name}, ${try(vm.public_ip_address, "no public ip")}"
  ]
}
