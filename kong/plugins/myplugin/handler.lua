local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local plugin = require("kong.plugins.base_plugin"):extend()
local version = require("version")


plugin.VERSION  = "1.0.0"
plugin.PRIORITY = 10


function plugin:new()
  plugin.super.new(self, plugin_name)
end


function version_in_range(version_request, version_range)
  local greater_than_lower_bound = (not version_range[1]) or (version(version_request) >= version(version_range[1]))
  local less_than_uppper_bound = (not version_range[2]) or (version(version_request) <= version(version_range[2]))

  return greater_than_lower_bound and less_than_uppper_bound
end


function plugin:access(plugin_conf)
  plugin.super.access(self)

  local received_request = {
    version = ngx.req.get_headers()["mobile-version"],
    host = kong.request.get_host(),
    path = kong.request.get_path(),
    method = kong.request.get_method()
  }

  if not received_request.version then return end

  for i = 1, #plugin_conf.blacklist do
    local blacklist_request = plugin_conf.blacklist[i]

    local is_method_matched = not blacklist_request.method or received_request.method == blacklist_request.method
    local is_host_matched = not blacklist_request.host or received_request.host == blacklist_request.host
    local is_path_matched = not blacklist_request.path or string.find(received_request.path, blacklist_request.path)
    local is_version_in_range = not blacklist_request.version_range or version_in_range(received_request.version, blacklist_request.version_range)

    if is_method_matched and is_host_matched and is_path_matched and is_version_in_range then
      return ngx.exit(299)
    end
  end
end


return plugin
