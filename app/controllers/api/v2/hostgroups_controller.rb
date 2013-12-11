module Api
  module V2
    class HostgroupsController < V2::BaseController

      include Api::Version2
      include Api::TaxonomyScope

      before_filter :find_resource, :only => %w{show update destroy snapshot}

      api :GET, "/hostgroups/", "List all hostgroups."
      param :search, String, :desc => "filter results"
      param :order, String, :desc => "sort results"
      param :page, String, :desc => "paginate results"
      param :per_page, String, :desc => "number of entries per request"

      def index
        @hostgroups = Hostgroup.includes(:hostgroup_classes, :group_parameters).
          search_for(*search_options).paginate(paginate_options)
      end

      api :GET, "/hostgroups/:id/", "Show a hostgroup."
      param :id, :identifier, :required => true

      def show
      end

      api :POST, "/hostgroups/", "Create an hostgroup."
      param :hostgroup, Hash, :required => true do
        param :name, String, :required => true
        param :parent_id, :number
        param :environment_id, :number
        param :operatingsystem_id, :number
        param :architecture_id, :number
        param :medium_id, :number
        param :ptable_id, :number
        param :puppet_ca_proxy_id, :number
        param :subnet_id, :number
        param :domain_id, :number
        param :puppet_proxy_id, :number
      end

      def create
        @hostgroup = Hostgroup.new(params[:hostgroup])
        process_response @hostgroup.save
      end

      api :PUT, "/hostgroups/:id/", "Update an hostgroup."
      param :id, :identifier, :required => true
      param :hostgroup, Hash, :required => true do
        param :name, String
        param :parent_id, :number
        param :environment_id, :number
        param :operatingsystem_id, :number
        param :architecture_id, :number
        param :medium_id, :number
        param :ptable_id, :number
        param :puppet_ca_proxy_id, :number
        param :subnet_id, :number
        param :domain_id, :number
        param :puppet_proxy_id, :number
      end

      def update
        process_response @hostgroup.update_attributes(params[:hostgroup])
      end

      api :DELETE, "/hostgroups/:id/", "Delete an hostgroup."
      param :id, :identifier, :required => true

      def destroy
        process_response @hostgroup.destroy
      end

      api :GET, "/hostgroups/:id/snapshot", "Snapshot a hostgroup."
      param :id, :identifier, :required => true
      param :host, Hash do
        param :name,                String
        param :compute_resource_id, :number
        param :hostgroup_id,        :number
        param :build,               :bool
        param :managed,             :bool
        param :compute_attributes, Hash do
          param :flavor_ref, :number
          param :network,    String
          param :image_ref,  String
        end
      end

      def snapshot
        render :json => "should not be here, foreman-tasks/dynflow should intercept this!"
        return

        # This code is kept for reference while working on Foreman-Tasks

        #hash = HashWithIndifferentAccess.new({
        #  :name                => @hostgroup.name.downcase,
        #  :compute_resource_id => ComputeResource.first.id,
        #  :hostgroup_id        => @hostgroup.id,
        #  :build               => 1,
        #  :managed             => true,
        #  :compute_attributes  => {
        #    :flavor_ref          => 1,
        #    :network             => "public",
        #    :image_ref           => ComputeResource.first.images.first.uuid
        #  }
        #})
        #hash.merge!(params[:host]) if params[:host].present?
        #progress_id = "hg_imaging_#{@hostgroup.id}"
        #Hostgroup.delay.snapshot!(@hostgroup.id,User.current.id,progress_id,hash)
        #process_response true

      end

    end
  end
end
