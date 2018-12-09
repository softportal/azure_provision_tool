def ip
    return @ip if @ip
    begin

        @ip = @network_client.public_ipaddresses.get(GROUP_NAME, IP).ip_address
    rescue Exception => e
        ''
    end
end

def deployed?
    %x(ssh -o ConnectTimeout=5 #{@conf[:user]}@#{ip} 'hostname')[0..-2] == VM_NAME
end

def status
    puts("running")    if deployed?
    puts("undeployed") if !deployed?
end

def execute(action)
    raise 'app is undeployed!' unless deployed?

    %x(ssh #{@conf[:user]}@#{ip} '#{action}')
end

def provision(action)
    script = @conf[:provision][action]
    execute("curl #{script}| bash")
end
