-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

-- load the base plugin object and create a subclass
local plugin = require("kong.plugins.base_plugin"):extend()

local version = require("version")

plugin.VERSION  = "1.0.0"
plugin.PRIORITY = 10


function plugin:new()
  plugin.super.new(self, plugin_name)
end


function version_in_range(version_request, version_range)
  if not version_range then return true end

  local greater_than_lower_bound = (not version_range[1]) or
  (version(version_request) >= version(version_range[1]))

  local less_than_uppper_bound = (not version_range[2]) or
  (version(version_request) <= version(version_range[2]))

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

    if received_request.method == blacklist_request.method and
      received_request.host == blacklist_request.host and
      version_in_range(received_request.version, blacklist_request.version_range) and
      string.find(received_request.path, blacklist_request.path) then
      return ngx.exit(299)
    end
  end
end


return plugin
