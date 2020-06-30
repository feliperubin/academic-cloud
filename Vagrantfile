# -*- mode: ruby -*-
# vi: set ft=ruby :
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# Date: First Semester of 2020
# About: A Vagrantfile that allows the
# provisioning of a multi-machine environment
# by reading a quite simple, YAML file definition.

# Read YAML with host configurations

# Capabilities:
# 1. Networking: 
#   => Public or Private, NICs (bridges), 
#   => DHCP and Static, or configure it later manually.
# 2. Hardware: 
#   => vNICS (virtual interfaces), 
#   => RAM(MB), vCPUS, NestedVT(Hardware Acceleration)
#   => Extra Disks(GB), Linked Clone or not for Disk0
# 3. Connectivity
#   => Enable/Disable X11 Forwarding
#   => Hostname, set or not VM global Name (shows in UI) namelabel: true
#   => Use GUI true/false
# network interfaces, public, private, host only
# 



require 'yaml'
hosts = YAML.load_file(File.join(File.dirname(__FILE__), 'hosts.yml'))

# vagrant_action = ARGV[0]
# puts "#{vagrant_action}"


# Discover the provider
provider = (ENV['VAGRANT_DEFAULT_PROVIDER'] || :virtualbox).to_sym
ARGV.each do |a|
  if a.split("=")[0] == "--provider"
    provider = a.split("=")[1]
  end
end

# Parallels Desktop Disable Parallel Provisioning
# If running with Paralllels Desktop, do not run it in parallel. 
# There's currently a bug which I've already created an issue with 
# the Parallels (see [issue](https://github.com/Parallels/vagrant-parallels/issues/357)) 
if "#{provider}" == "parallels"
  ENV['VAGRANT_NO_PARALLEL'] = 'yes'
end

# Workaround to this implementation, otherwise vmware fusion will always create
# a disk. It's a language issue. Fix me later.
if provider == "vmware_fusion"
  enabled_vmware_fusion_disk_creation = true
else
  enabled_vmware_fusion_disk_creation = false
end

# def boolspec(key,default)
#     return ( ! key.nil? ) && key == "true" ? true : false
# end

def to_bool(str,default)
  if str.nil? then
    return default
  end
  return str == "true"
end


Vagrant.configure("2") do |config|

  # Supported Hypervisors (try order)
  # config.vm.provider "parallels"
  # config.vm.provider "vmware_fusion"
  # config.vm.provider "virtualbox"
  # config.vm.provider "libvirt"
  # hosts.size()
  # puts "string"
  # puts "#{a.class}"  # Prints class of object
  # Ruby also supports x == y ? z : w
  # OBS: Use triggers later on with maybe a counter,
  # to run ansible only after all vms are provisioned.
  # Use this to know when the last VM will be provisioned.
  # config.ssh.forward_agent = true

  # if "#{provider}"
  def configure_virtualbox(hnode,h)
    hnode.vm.provider :virtualbox do |v, override|
      system "vagrant plugin install vagrant-vbguest" unless Vagrant.has_plugin? "vagrant-vbguest"
      v.memory = h["mem"]
      v.cpus = h["cpu"]

      v.gui = "#{h["gui"]}"
      v.linked_clone = "#{h["linkedclone"]}"
      if h["namelabel"] == "true"
        v.name = h["name"]
      end

      if "#{h["nestedvt"]}" == "true"
        v.customize ["modifyvm",:id,"--hwvirtex", "on"]
        v.customize ["modifyvm",:id,"--nested-hw-virt", "on"]
        v.customize ["modifyvm",:id,"--nestedpaging", "on"]
        v.customize ["modifyvm",:id,"--largepages", "on"]
        v.customize ["modifyvm",:id,"--vtxux", "on"]
        v.customize ["modifyvm",:id,"--vtxvpid", "on"]
      end

      h["disk"].to_a.each_index do |disk|
        diskname = File.join(File.dirname(File.expand_path(__FILE__)), ".virtualbox", "#{hnode.vm.hostname}-#{disk+1}.vdi")
        unless File.exist?(diskname)
          v.customize ['createhd', '--filename', diskname, '--size', h["disk"][disk]["size"] * 1024]
        end
        v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', disk+1, '--device', 0, '--type', 'hdd', '--medium', diskname]
      end
      
      # Video Configurations
      if "#{h["video3d"]}" == "true"
          v.customize ["modifyvm", :id, "--accelerate3d", "on"]
      else
          v.customize ["modifyvm", :id, "--accelerate3d", "off"]     
      end
      if h["vram"].to_i > 0
          v.customize ["modifyvm", :id, "--vram",h["vram"]]
      end
    end
  end
  def configure_parallels(hnode,h)
   hnode.vm.provider :parallels do |v, override|
      system "vagrant plugin install vagrant-parallels" unless Vagrant.has_plugin? "vagrant-parallels"
      if h["vmlabel"] == "true"
        v.name = h["name"]
      end
      v.memory = h["mem"]
      v.cpus = h["cpu"]
      if "#{h["nestedvt"]}" == "true"
        v.customize ["set", :id, "--nested-virt", "on"]
      end
      #v.check_guest_tools = true
      #v.update_guest_tools = true
       # or any of <coherence | fullscreen | modality | window | headless >
      if "#{h["gui"]}" == "true"
        v.customize ["set", :id, "--startup-view", "window"] 
      else
        v.customize ["set", :id, "--startup-view", "headless"] 
      end
      #Enables adaptive hypervisor, better core usage
      v.customize ["set", :id, "--adaptive-hypervisor","on"]
      v.customize ["set", :id, "--sync-ssh-ids","on"]
      v.customize ["set", :id, "--time-sync","on"]
      # v.customize ["set", :id, "--device-add", "hdd",
      v.linked_clone = "#{h["linkedclone"]}"
      h["disk"].to_a.each_index do |disk|
        v.customize ['set', :id, '--device-add', 'hdd', '--size', h["disk"][disk]["size"] * 1024]
      end
      
      # Video Configurations
      if "#{h["video3d"]}" == "true"
          v.customize ["set", :id, "--3d-accelerate","highest"]
      else
          # could also be off,highest, dx9
          v.customize ["set", :id, "--3d-accelerate","off"]
      end
      if h["vram"].to_i > 0
          v.customize ["set", :id, "--videosize", h["vram"]]
      end
    end    
  end
  def configure_vmware_fusion(hnode,h)
    hnode.vm.provider :vmware_fusion do |v, override|
      if h["namelabel"]
        v.vmx['displayname'] = h["name"]
      end
      v.vmx['memsize'] = h["mem"]
      v.vmx['numvcpus'] = h["cpu"]
      v.gui = "#{h["gui"]}"
      v.linked_clone = "#{h["linkedclone"]}"
      if "#{h["nestedvt"]}" == "true"
        v.vmx["vhv.enable"] = "TRUE"
      end
      # if $enabled_vmware_fusion_disk_creation
      vdiskmanager = "/Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager"
      dir = File.join(File.dirname(File.expand_path(__FILE__)), ".vmware")
      if File.exist?(vdiskmanager)
        h["disk"].to_a.each_index do |disk|
          unless File.directory?( dir )
            Dir.mkdir dir
          end
          diskname = File.join(dir, "#{hnode.vm.hostname}-#{disk+1}.vmdk")
          unless File.exist?(diskname)
            `/Applications/VMware\\ Fusion.app/Contents/Library/vmware-vdiskmanager -c -s #{h["disk"][disk]["size"]}GB -a lsilogic -t 1 #{diskname}`
          end
          v.vmx["scsi0:#{disk+1}.filename"] = diskname
          v.vmx["scsi0:#{disk+1}.present"] = 'TRUE'
          v.vmx["scsi0:#{disk+1}.redo"] = ''
        end
      end
      # end
      
      # Video Configs
      vrambytes = h["vram"].to_i * 1024
      if vrambytes > 65535
        v.vmx["svga.vramSize"] = "#{vrambytes}"
      end
      if "#{h["video3d"]}" == "true"
        v.vmx['mks.enable3d'] = "TRUE"
      else
        v.vmx['mks.enable3d'] = "FALSE"
      end
    end    
  end
  def configure_libvirt(hnode,h)
      hnode.vm.provider :libvirt do |v,override|
        system "vagrant plugin install vagrant-libvirt" unless Vagrant.has_plugin? "vagrant-libvirt"
        v.cpus = h["cpu"]
        v.memory = h["mem"]
        # v.socket # Path to libvirt Socket
        # where qemu/kvm is running
        #v.host = "example.com"
        if "#{h['nestedvt']}" == "true"
            v.nested = h["nestedvt"]
            v.memorybacking :hugepages
            v.memorybacking :nosharepages
            v.memorybacking :locked
            v.memorybacking :source, :type => 'file'
            v.memorybacking :access, :mode => 'shared'
            v.memorybacking :allocation, :mode => 'immediate'
        end
        h["disk"].to_a.each_index do |disk|
            v.storage :file, :size => h["disk"][disk]["size"]
            # For most, use the types raw and qcow2.
        end
        v.volume_cache = 'none'
        if "#{h["gui"]}" == "true"
            v.graphics_type = "vnc"
        else
            v.graphics_type = "none"
        end
        v.video_vram = h["vram"]
        v.host = 'localhost'
        v.uri = 'qemu:///system'
        #v.driver = "qemu"
        #v.driver = "kvm"
      end
  end
  #   def configure_vbox_provider(config, name, ip, memory = 384)
  #   config.vm.provider :virtualbox do |vbox, override| 
  #     # override box url
  #     override.vm.box = "opscode_ubuntu-13.04_provisionerless"
  #     override.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/opscode_ubuntu-13.04_provisionerless.box"
  #     # configure host-only network
  #     override.vm.hostname = "#{name}.local"
  #     override.vm.network :private_network, ip: ip
  #     # enable cachier for local vbox vms
  #     override.cache.auto_detect = true

  #     # virtualbox specific configuration
  #     vbox.customize ["modifyvm", :id, 
  #       "--memory", memory,
  #       "--name", name
  #     ] 
  #   end
  # end


  global_box="generic/ubuntu1804"
  hosts.each_index do |gi|
    h = hosts[gi]
    # If not defined, set defaults

    h["provider"] = provider unless h.key?("provider")
    # Physical Resource Configuration

    h["linkedclone"] = "true" unless h.key?("linkedclone")
    # h["linkedclone"] = true unless h.key?("linkedclone")
    h["nestedvt"] = "false" unless h.key?("nestedvt")
    h["mem"] = 512 unless h.key?("mem")
    h["cpu"] = 1 unless h.key?("cpu")
    if h.key?("box")
      global_box=h["box"]
    else
      h["box"] = global_box
    end
    h["box"] = "bento/ubuntu-18.04" unless h.key?("box")
    h["namelabel"] = true unless h.key?("namelabel")

    # Video Configurations
    h["x11"] = "false" unless h.key?("x11")
    h["gui"] = "false" unless h.key?("gui")

    h["vram"] = "0" unless h.key?("vram")
    h["video3d"] = "false" unless h.key?("video3d")
    # if h.key?("key")
    #   config.ssh.private_key_path = [h["key"]["private"], "~/.vagrant.d/insecure_private_key"]
    #   config.vm.provision "file", source: h["key"]["public"], destination: "~/.ssh/authorized_keys"        
    # end
    config.vm.define h["name"] do |hnode|
      ######## Begin Network Configurations ########
      (h["network"].to_a).each do |net|
        net["auto_config"] = true unless net.key?("auto_config")
        net["kind"] = "private_network" unless net.key?("kind")
        net["type"] = "dhcp" unless net.key?("type") or net.key?("ip")
        if net["type"] == "forwarded_port"
          hnode.vm.network net["type"], guest: net["guest"], host: net["host"]
        elsif net["type"] == "dhcp"

          # puts "#{net["kind"]},#{net["auto_config"]}"
          # hnode.vm.network "private_network", auto_config: false, adapter: 1
          if net.key?("bridge")
            hnode.vm.network net["kind"], type: "dhcp", auto_config: net["auto_config"], bridge: net["bridge"]
          else
            hnode.vm.network net["kind"], type: "dhcp", auto_config: net["auto_config"]
          end
        else
          if net.key?("bridge")
            hnode.vm.network net["kind"], ip: net["ip"], netmask: net["mask"], auto_config: net["auto_config"], bridge: net["bridge"]
          else
            hnode.vm.network net["kind"], ip: net["ip"], netmask: net["mask"], auto_config: net["auto_config"]
          end
        end
      end
      ######## End Network Configurations ########
      hnode.vm.hostname = h["name"] # Set the hostname
      hnode.vm.box = h["box"]
      hnode.ssh.forward_x11 = "#{h["x11"]}" # Enables or not X11 defaults to disabled
      hnode.vm.synced_folder '.', '/home/vagrant/share', disabled: true # For now, don't support synced_folder
      # Commands Exclusive to Each Machine, All support the 
      # very 'same' specs but through different commands      
      case "#{provider}"
        when "parallels"
          configure_parallels(hnode,h)
        when "vmware_fusion"
          configure_vmware_fusion(hnode,h)
        when "libvirt"
          configure_libvirt(hnode,h)
        when "virtualbox"
          configure_virtualbox(hnode,h)
      end
    end
  end
end
