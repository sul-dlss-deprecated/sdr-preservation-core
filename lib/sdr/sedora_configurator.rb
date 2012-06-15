if ENABLE_SOLR_UPDATES == true
  ENABLE_SOLR_UPDATES=false
end
module Sdr

  # @see https://github.com/projecthydra/active_fedora/wiki/File-Free-Configuration
  class SedoraConfigurator
    def initialize
      @config = {
        # allowable_options = [:url, :user, :password, :timeout, :open_timeout, :ssl_client_cert, :ssl_client_key, :validateChecksum]
        :fedora => { :url => Config.sedora.url, :user => Config.sedora.user, :password => Config.sedora.password },
        :solr => {:url => 'http://localhost:8983/solr/test'},
        :predicates => YAML.load(File.read(File.expand_path('../../../config/predicate_mappings.yml',__FILE__)))
      }
    end

    def init *args; end

    def fedora_config
      @config[:fedora]
    end

    def solr_config
      @config[:solr]
    end

    def predicate_config
      @config[:predicates]
    end
  end

end
