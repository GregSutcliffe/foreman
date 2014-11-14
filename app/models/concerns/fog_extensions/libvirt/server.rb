module FogExtensions
  module Libvirt
    module Server
      extend ActiveSupport::Concern

      include ActionView::Helpers::NumberHelper

      attr_accessor :image_id

      def to_s
        name
      end

      def nics_attributes=(attrs); end

      def volumes_attributes=(attrs); end

      # Libvirt expect units in KB, while we use bytes
      def memory
        attributes[:memory_size].to_i * 1024
      end

      def memory=(mem)
        attributes[:memory_size] = mem.to_i / 1024 if mem
      end

      def reset
        poweroff
        start
      end

      def vm_description
        _("%{cpus} CPUs and %{memory} memory") % {:cpus => cpus, :memory => number_to_human_size(memory.to_i)}
      end

      def interfaces
        nics
      end

      def select_nic(fog_nics, attrs, identifier)
        nic = attrs['nics_attributes'].detect  do |k,v|
          v['id'] == identifier # should only be one
        end.last
        return nil if nic.nil?
        match =   fog_nics.detect { |fn| fn.network == nic['network'] } # just grab any nic on the same network
        match ||= fog_nics.detect { |fn| fn.bridge  == nic['bridge']  } # no network? try a bridge...
        match
      end

    end
  end
end
