# initialize puppet related pagelets
Pagelets::Manager.with_key "hosts/_form" do |mgr|
  mgr.add_pagelet :main_tabs,
    :id => :puppet_klasses,
    :name => _("Puppet Classes"),
    :partial => "hosts/puppet/puppet_classes_tab",
    :priority => 100,
    :onlyif => proc { |host, context| context.instance_eval { accessible_resource(host, :smart_proxy, :name, association: :puppet_proxy).present? } }

  mgr.add_pagelet :main_tab_fields,
    :partial => "hosts/puppet/main_tab_fields",
    :priority => 100
end
