#
# Cookbook Name:: cookbook-spark
# Recipe:: default
#
# Copyright 2013, Holden Karau
#
# BSD-3 Clause
#

# Create the home directory
package("git")
directory node[:spark][:home] do
  owner node[:spark][:username]
  group node[:spark][:username]
  mode 744
  action :create
end

# Override some java settings
node.default['java']['oracle']['accept_oracle_download_terms'] = true
node.default['java']['install_flavor'] = 'oracle'
# Specify the scala version we are using
node.default[:scala][:version] = "2.9.3"
node.default[:scala][:url] = "http://www.scala-lang.org/downloads/distrib/files/scala-2.9.3.tgz"
# Create the scala directory
directory "{node[:spark][:home]}/scala" do
  owner node[:spark][:username]
  group node[:spark][:username]
  mode 0744
  action :create
end
node.default[:scala][:home] = node[:spark][:home]+"/scala"
# Install scala
include_recipe "scala::default"

# Clone 
node.default[:spark][:spark_path] = node[:spark][:home]+"/spark"
directory node[:spark][:spark_path] do
  owner node[:spark][:username]
  group node[:spark][:username]
  mode 0744
  action :create
end
git node[:spark][:spark_path] do
  user node[:spark][:username]
  group node[:spark][:username]
  repository node[:spark][:git_repository]
  reference node[:spark][:git_revision]
  action :sync
  notifies :run, "bash[build_spark]"
end

bash "build_spark" do
  user node[:spark][:username]
  group node[:spark][:group]
  cwd node[:spark][:spark_path]
  code <<-EOH
    ./sbt/sbt package
  EOH
end

template node[:spark][:spark_path]+"/conf/spark-env.sh" do
  source "spark-env.sh.erb"
  owner node[:spark][:username]
  group node[:spark][:group]
  mode 00600
end

template node[:spark][:spark_path]+"/conf/slaves" do
  source "slaves.erb"
  owner node[:spark][:username]
  group node[:spark][:group]
  mode 00600
end

service "spark_master" do
  start_command "{node[:spark][:home]/spark/bin/start-master.sh"
  stop_command "{node[:spark][:home]/spark/bin/stop-master.sh"
end
service "spark_worker" do
  start_command "{node[:spark][:home]/spark/bin/start-slave.sh spark://{node[:spark][:master]}:{node[:spark][:master_port]}"
  stop_command "{node[:spark][:home]/spark/bin/stop-slave.sh spark://{node[:spark][:master]}:{node[:spark][:master_port]}"
end
