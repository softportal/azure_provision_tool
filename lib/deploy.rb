require 'azure_mgmt_resources'
require 'azure_mgmt_compute'
require 'azure_mgmt_network'
require 'azure_mgmt_storage'

Storage = Azure::Storage::Profiles::Latest::Mgmt
Network = Azure::Network::Profiles::V2018_03_01::Mgmt
Compute = Azure::Compute::Profiles::Latest::Mgmt
Resources = Azure::Resources::Profiles::Latest::Mgmt

StorageModels = Storage::Models
NetworkModels = Network::Models
ComputeModels = Compute::Models
ResourceModels = Resources::Models

# PRINT METHODS
##################################################
def print_item_auz(group)
  puts "Created:"
  puts
  puts "\tName: #{group.name}"
  puts "\tId: #{group.id}"
  puts "\tLocation: #{group.location}"
  puts "\tTags: #{group.tags}"
  #print_properties(group.properties)
end

def print_machines(group_name)
    @compute_client.virtual_machines.list(group_name).each do |vm|
        print_item(vm)
    end
end

def print_group(resource)
  puts "\tname: #{resource.name}"
  puts "\tid: #{resource.id}"
  puts "\tlocation: #{resource.location}"
  puts "\ttags: #{resource.tags}"
  puts "\tproperties:"
  print_item(resource.properties)
end

def print_item(resource)
  resource.instance_variables.sort.each do |ivar|
    str = ivar.to_s.gsub /^@/, ''
    if resource.respond_to? str.to_sym
      puts "\t\t#{str}: #{resource.send(str.to_sym)}"
    end
  end
  puts "\n\n"
end
#######################################################

def get_resources()
  puts 'Listing all of the resources within the group'
  @resource_client.resource_groups.list_resources(GROUP_NAME).each do |res|
    print_item res
  end
end

def init
  creds = @conf[:credentials]
  subscription_id = creds[:sub] || '11111111-1111-1111-1111-111111111111' # your Azure Subscription Id
  provider = MsRestAzure::ApplicationTokenProvider.new(creds[:dir], creds[:client], creds[:secret])
  credentials = MsRest::TokenCredentials.new(provider)

  options = {
      tenant_id: creds[:dir],
      client_id: creds[:client],
      client_secret: creds[:secret],
      subscription_id: creds[:sub]
  }


  @resource_client = Resources::Client.new(options)
  @network_client = Network::Client.new(options)
  @storage_client = Storage::Client.new(options)
  @compute_client = Compute::Client.new(options)
end

def deploy
  resource_group_params = ResourceModels::ResourceGroup.new.tap do |rg|
    rg.location = WEST_EU
  end

  # Create Resource group
  puts 'Creating Resource Group...'
  print_group @resource_client.resource_groups.create_or_update(GROUP_NAME, resource_group_params)

  postfix = rand(1000)
  storage_account_name = "#{GROUP_NAME}storage"
  puts "Creating a Standard storage account with encryption..."
  storage_create_params = StorageModels::StorageAccountCreateParameters.new.tap do |account|
    account.location = WEST_EU
    account.sku = StorageModels::Sku.new.tap do |sku|
      sku.name = "Standard_LRS"
      sku.tier = "Standard"
    end
    account.kind = StorageModels::Kind::Storage
    account.encryption = StorageModels::Encryption.new.tap do |encrypt|
      encrypt.services = StorageModels::EncryptionServices.new.tap do |services|
        services.blob = StorageModels::EncryptionService.new.tap do |service|
          service.enabled = false
        end
      end
    end
  end
  print_item storage_account = @storage_client.storage_accounts.create(GROUP_NAME, storage_account_name, storage_create_params)


  puts 'Creating a virtual network for the VM...'
  vnet_create_params = NetworkModels::VirtualNetwork.new.tap do |vnet|
      vnet.location = WEST_EU
      vnet.address_space = NetworkModels::AddressSpace.new.tap do |addr_space|
          addr_space.address_prefixes = ['10.0.0.0/16']
      end
      vnet.dhcp_options = NetworkModels::DhcpOptions.new.tap do |dhcp|
          dhcp.dns_servers = ['8.8.8.8']
      end

      subnet = NetworkModels::Subnet.new.tap do |subnet|
          subnet.name                   = 'subnet'
          subnet.address_prefix         = '10.0.0.0/24'
      end

      vnet.subnets = [ subnet ]
  end
  print_item vnet = @network_client.virtual_networks.create_or_update(GROUP_NAME, "#{GROUP_NAME}-vnet", vnet_create_params)

  puts 'Creating a public IP address for the VM...'
  public_ip_params = NetworkModels::PublicIPAddress.new.tap do |ip|
    ip.location = WEST_EU
    ip.public_ipallocation_method = NetworkModels::IPAllocationMethod::Dynamic
    ip.dns_settings = NetworkModels::PublicIPAddressDnsSettings.new.tap do |dns|
      dns.domain_name_label = 'masteriot'
    end
  end
  print_item public_ip = @network_client.public_ipaddresses.create_or_update(GROUP_NAME, IP, public_ip_params)

  vm = create_vm(VM_NAME, storage_account, vnet.subnets[1], public_ip)

  @ip = @network_client.public_ipaddresses.get(GROUP_NAME, IP).ip_address
  #export_template(@resource_client)

  puts "your application is deployed: #{@ip}, your user is :#{@conf[:user]}"
end

def delete_rs()
  @resource_client.resource_groups.delete(GROUP_NAME)
  puts "\nDeleted: #{GROUP_NAME}"
end


def export_template(resource_client)
  puts "Exporting the resource group template for #{GROUP_NAME}"
  export_result = resource_client.resource_groups.export_template(
      GROUP_NAME,
      ResourceModels::ExportTemplateRequest.new.tap{ |req| req.resources = ['*'] }
  )
  puts export_result.template
  puts ''
end

# Create a Virtual Machine and return it
def create_vm(vm_name, storage_acct, subnet, public_ip)
  location = WEST_EU

  puts "Creating security group..."
  params_nsg = NetworkModels::NetworkSecurityGroup.new.tap do |sg|
      sr = NetworkModels::SecurityRule.new.tap do |rule|
               rule.name                       = 'main'
               rule.description                = 'default rule'
               rule.protocol                   = '*'
               rule.source_address_prefix      = '*'
               rule.destination_address_prefix = '*'
               rule.source_port_range          = '*'
               rule.access                     = 'Allow'
               rule.priority                   = 100
               rule.direction                  = 'Inbound'
               rule.destination_port_ranges    = ['22','80', '443', '50051']
      end

      sg.location            = WEST_EU
      sg.security_rules      = [ sr ]
  end
  nsg = @network_client.network_security_groups.create_or_update(GROUP_NAME,'coffe-grpc_rules', params_nsg)

  puts "Creating a network interface for the VM #{vm_name}"
  print_item nic = @network_client.network_interfaces.create_or_update(
      GROUP_NAME,
      "nic-#{vm_name}",
      NetworkModels::NetworkInterface.new.tap do |interface|
        interface.location = WEST_EU
        interface.network_security_group = nsg
        interface.ip_configurations = [
            NetworkModels::NetworkInterfaceIPConfiguration.new.tap do |nic_conf|
              nic_conf.name = "nic-#{vm_name}"
              nic_conf.private_ipallocation_method = NetworkModels::IPAllocationMethod::Dynamic
              nic_conf.subnet = subnet
              nic_conf.public_ipaddress = public_ip
            end
        ]
      end
  )

  puts 'Creating a Ubuntu 16.04.0-LTS Standard DS2 V2 virtual machine w/ a public IP'
  vm_create_params = ComputeModels::VirtualMachine.new.tap do |vm|
    vm.location = location
    vm.os_profile = ComputeModels::OSProfile.new.tap do |os_profile|
      os_profile.computer_name = vm_name
      os_profile.admin_username = @conf[:user]
      os_profile.admin_password = 'Asd1234554321'
    end

    vm.storage_profile = ComputeModels::StorageProfile.new.tap do |store_profile|
      store_profile.image_reference = ComputeModels::ImageReference.new.tap do |ref|
        ref.publisher = 'canonical'
        ref.offer = 'UbuntuServer'
        ref.sku = '16.04.0-LTS'
        ref.version = 'latest'
      end
      store_profile.os_disk = ComputeModels::OSDisk.new.tap do |os_disk|
        os_disk.name = "os-disk-#{vm_name}"
        os_disk.caching = ComputeModels::CachingTypes::None
        os_disk.create_option = ComputeModels::DiskCreateOptionTypes::FromImage
        os_disk.vhd = ComputeModels::VirtualHardDisk.new.tap do |vhd|
          vhd.uri = "https://#{storage_acct.name}.blob.core.windows.net/rubycontainer/#{vm_name}.vhd"
        end
      end
    end

    vm.hardware_profile = ComputeModels::HardwareProfile.new.tap do |hardware|
      hardware.vm_size = ComputeModels::VirtualMachineSizeTypes::StandardDS2V2
    end

    vm.network_profile = ComputeModels::NetworkProfile.new.tap do |net_profile|
      net_profile.network_interfaces = [
          ComputeModels::NetworkInterfaceReference.new.tap do |ref|
            ref.id = nic.id
            ref.primary = true
          end
      ]
    end
  end

  vm_create_params.os_profile.linux_configuration = ComputeModels::LinuxConfiguration.new.tap do |linux|
        linux.disable_password_authentication = false
        linux.ssh = ComputeModels::SshConfiguration.new.tap do |ssh_config|
            keys = []
            @conf[:access].each do |key|
              k = ComputeModels::SshPublicKey.new.tap do |pub_key|
                  pub_key.key_data = key
                  pub_key.path = '/home/user_admin/.ssh/authorized_keys'
              end
              keys << k
            end
          ssh_config.public_keys = keys
        end
    end

  print_item vm = @compute_client.virtual_machines.create_or_update(GROUP_NAME, vm_name, vm_create_params)
  vm
end
