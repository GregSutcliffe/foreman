class Image < ActiveRecord::Base
  belongs_to :operatingsystem
  belongs_to :compute_resource
  belongs_to :architecture
  belongs_to :hostgroup

  has_many_hosts
  validates :username, :name, :operatingsystem_id, :compute_resource_id, :architecture_id, :presence => true
  validates :uuid, :presence => true, :uniqueness => {:scope => :compute_resource_id}

  scoped_search :on => [:name, :username], :complete_value => true
  scoped_search :in => :compute_resources, :on => :name, :complete_value => :true, :rename => "compute_resource"
  scoped_search :in => :architecture, :on => :id, :rename => "architecture"
  scoped_search :in => :operatingsystem, :on => :id, :rename => "operatingsystem"
  scoped_search :on => :hostgroup_id, :rename => "hostgroup", :ext_method => :search_by_hostgroup


  def self.search_by_hostgroup(key, operator, value)
    # allows to find parent hostgroup images as well.
    ids = Hostgroup.find(value).try(:path_ids)
    { :conditions => sanitize_sql_for_conditions({ :hostgroup_id => ids }) }
  end
end
