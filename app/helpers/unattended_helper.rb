module UnattendedHelper

  def ks_console
    (@port and @baud) ? "console=ttyS#{@port},#{@baud}": ""
  end

  def grub_pass
    @grub ? "--md5pass=#{@host.root_pass}": ""
  end

  def root_pass
    @host.root_pass
  end

  def foreman_url(action = "built")
    url_for :only_path => false, :controller => "/unattended", :action => action,
      :host      => (Setting[:foreman_url] unless Setting[:foreman_url].blank?),
      :protocol  => 'http',
      :token     => (@host.token.value unless @host.token.nil?)
  end
  attr_writer(:url_options)

  # provide embedded snippets support as simple erb templates
  def snippets(file)
    if ConfigTemplate.where(:name => file, :snippet => true).empty?
      render :partial => "unattended/snippets/#{file}"
    else
      return snippet(file.gsub(/^_/, ""))
    end
  end

  def snippet name
    if (template = ConfigTemplate.where(:name => name, :snippet => true).first)
      Rails.logger.debug "rendering snippet #{template.name}"
      begin
        methods   = [ :foreman_url, :grub_pass, :snippet, :snippets,
          :ks_console, :root_pass, :multiboot, :jumpstart_path, :install_path,
          :miniroot, :media_path ]
        variables = {:arch => @arch, :host => @host, :osver => @osver,
          :mediapath => @mediapath, :static => @static, :yumrepo => @yumrepo,
          :dynamic => @dynamic, :epel => @epel, :kernel => @kernel, :initrd => @initrd,
          :preseed_server => @preseed_server, :preseed_path => @preseed_path }
        return SafeRender.new(:methods => methods, :variables => variables).parse_string template.template
      rescue Exception => exc
        raise "The snippet '#{name}' threw an error: #{exc}"
      end
    else
      raise "The specified snippet '#{name}' does not exist, or is not a snippet."
    end
  end

end
