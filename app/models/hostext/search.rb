module Hostext
  module Search
    def self.included(base)
      base.class_eval do
        has_many :search_parameters, :class_name => 'Parameter', :foreign_key => :reference_id
        belongs_to :search_users, :class_name => 'User', :foreign_key => :owner_id

        scoped_search :on => :name,          :complete_value => true, :default_order => true
        scoped_search :on => :last_report,   :complete_value => true
        scoped_search :on => :ip,            :complete_value => true
        scoped_search :on => :enabled,       :complete_value => {:true => true, :false => false}, :rename => :'status.enabled'
        scoped_search :on => :puppet_status, :complete_value => {:true => true, :false => false}, :rename => :'status.interesting'
        scoped_search :on => :puppet_status, :offset => Report::METRIC.index("applied"),         :word_size => Report::BIT_NUM, :rename => :'status.applied'
        scoped_search :on => :puppet_status, :offset => Report::METRIC.index("restarted"),       :word_size => Report::BIT_NUM, :rename => :'status.restarted'
        scoped_search :on => :puppet_status, :offset => Report::METRIC.index("failed"),          :word_size => Report::BIT_NUM, :rename => :'status.failed'
        scoped_search :on => :puppet_status, :offset => Report::METRIC.index("failed_restarts"), :word_size => Report::BIT_NUM, :rename => :'status.failed_restarts'
        scoped_search :on => :puppet_status, :offset => Report::METRIC.index("skipped"),         :word_size => Report::BIT_NUM, :rename => :'status.skipped'

        scoped_search :in => :model,       :on => :name,    :complete_value => true, :rename => :model
        scoped_search :in => :hostgroup,   :on => :name,    :complete_value => true, :rename => :hostgroup
        scoped_search :in => :domain,      :on => :name,    :complete_value => true, :rename => :domain
        scoped_search :in => :environment, :on => :name,    :complete_value => true, :rename => :environment

        scoped_search :in => :puppetclasses, :on => :name, :complete_value => true, :rename => :class, :only_explicit => true, :ext_method => :search_by_puppetclass
        scoped_search :in => :fact_values, :on => :value, :in_key=> :fact_names, :on_key=> :name, :rename => :facts, :complete_value => true, :only_explicit => true

        if SETTINGS[:unattended]
          scoped_search :in => :subnet,      :on => :network, :complete_value => true, :rename => :subnet
          scoped_search :on => :mac,           :complete_value => true
          scoped_search :on => :build,         :complete_value => {:true => true, :false => false}
          scoped_search :on => :installed_at,  :complete_value => true
          scoped_search :in => :operatingsystem, :on => :name, :complete_value => true, :rename => :os
        end

        if SETTINGS[:login]
          scoped_search :in => :search_users, :on => :login,     :complete_value => true, :only_explicit => true, :rename => :'user.login',     :ext_method => :search_by_user
          scoped_search :in => :search_users, :on => :firstname, :complete_value => true, :only_explicit => true, :rename => :'user.firstname', :ext_method => :search_by_user
          scoped_search :in => :search_users, :on => :lastname,  :complete_value => true, :only_explicit => true, :rename => :'user.lastname',  :ext_method => :search_by_user
          scoped_search :in => :search_users, :on => :mail,      :complete_value => true, :only_explicit => true, :rename => :'user.mail',      :ext_method => :search_by_user
        end

        def self.search_by_user(key, operator, value)
          key_name = key.sub(/^.*\./,'')
          users = User.all(:conditions => "#{key_name} #{operator} '#{value_to_sql(operator, value)}'")
          hosts = users.map(&:hosts).flatten
          opts  = hosts.empty? ? "= 'nil'" : "IN (#{hosts.map(&:id).join(',')})"

          return {:conditions => " hosts.id #{opts} " }
        end

        def self.search_by_puppetclass(key, operator, value)
          conditions  = "puppetclasses.name #{operator} '#{value_to_sql(operator, value)}'"
          hosts       = Host.all(:conditions => conditions, :joins => :puppetclasses, :select => 'DISTINCT hosts.id').map(&:id)
          host_groups = Hostgroup.all(:conditions => conditions, :joins => :puppetclasses, :select => 'DISTINCT hostgroups.id').map(&:id)

          opts = ''
          opts += "hosts.id IN(#{hosts.join(',')})"             unless hosts.blank?
          opts += " OR "                                        unless hosts.blank? || host_groups.blank?
          opts += "hostgroups.id IN(#{host_groups.join(',')})"  unless host_groups.blank?
          opts = "hosts.id = 'nil'"                             if hosts.blank? && host_groups.blank?
          return {:conditions => opts, :include => :hostgroup}
        end

        private

        def self.value_to_sql(operator, value)
          return value                 if operator !~ /LIKE/i
          return value.tr_s('%*', '%') if (value ~ /%|\*/)

          return "%#{value}%"
        end

      end
    end
  end
end
