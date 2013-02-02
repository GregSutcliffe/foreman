# Class to parse ERB with or without Safemode rendering. Needs a set
# of variables, usually something like:
#   @allowed_vars = { :host => @host }
# so that <%= @host.name %> has the right @host variable
#
class SafeRender

  def initialize args = {}
    @allowed_methods = args[:methods]   || []
    @allowed_vars    = args[:variables] || {}
  end

  def parse object
    return object if (Setting[:interpolate_erb_in_parameters] == false)

    # recurse over object types until we're dealing with a String
    if object.is_a? String
      return parse_string object
    elsif object.is_a? Array
      return object.map {|v| parse v}
    elsif object.is_a? Hash
      return object.merge(object){|k,v| parse v}
    else
      # Don't know how to parse this, send it back
      return object
    end
  end

  def parse_string string
    return unless string.is_a? String

    if Setting[:safemode_render]
      box = Safemode::Box.new self, @allowed_methods
      return box.eval(ERB.new(string, nil, '-').src, @allowed_vars)
    else
      @allowed_vars.each { |k,v| instance_variable_set "@#{k}", v }
      return ERB.new(string, nil, '-').result(binding)
    end
  end

end
