local helpers = require "spec.helpers"
local version = require("version").version or require("version")


local PLUGIN_NAME = "myplugin"
local KONG_VERSION = version(select(3, assert(helpers.kong_exec("version"))))


for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()
      local bp, route1

      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })

      local route2 = bp.routes:insert({
        hosts = { "test2.com" },
      })

      local route3 = bp.routes:insert({
        hosts = { "test3.com" },
      })

      local route4 = bp.routes:insert({
        hosts = { "test4.com" },
      })

      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {},
      }

      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route2.id },
        config = {
          blacklist = {
            {
              method = "GET",
              path = "status/200",
              host = "test2.com",
              version_range = {
                "1.0.0",
                "2.0.0"
              }
            }
          }
        },
      }

      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route3.id },
        config = {
          blacklist = {
            {
              version_range = {
                "1.0.0",
                "2.0.0"
              }
            }
          }
        },
      }

      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route4.id },
        config = {
          blacklist = {
            {
              path = "status/200",
              host = "test4.com",
            }
          }
        },
      }

      assert(helpers.start_kong({
        database   = strategy,
        nginx_conf = "spec/fixtures/custom_nginx.template",
        plugins = "bundled," .. PLUGIN_NAME
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)


    describe("no blacklist set", function()
      it("passes the request", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            host = "test1.com",
            ["mobile-version"] = "1.2.0"
          }
        })

        assert.response(r).has.status(200)
      end)
    end)


    describe("blacklist set", function()
      it("passes the request if it has no mobile-version header", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            host = "test2.com"
          }
        })

        assert.response(r).has.status(200)
      end)
    end)


    describe("only version_range is set", function()
      it("blocks the request if it matches in blacklist", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            host = "test3.com",
            ["mobile-version"] = "1.2.0"
          }
        })

        assert.response(r).has.status(299)
      end)
      
      it("passes the request if it doesn't match in blacklist", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            host = "test3.com",
            ["mobile-version"] = "2.3.0"
          }
        })

        assert.response(r).has.status(200)
      end)
    end)


    describe("only host and path are set", function()
      it("blocks the request if it matches in blacklist", function()
        local r1 = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            host = "test4.com",
            ["mobile-version"] = "1.2.0"
          }
        })

        assert.response(r1).has.status(299)

        local r2 = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            host = "test4.com"
          }
        })

        assert.response(r2).has.status(200)
      end)
      
      it("passes the request if it doesn't match in blacklist", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/500",
          headers = {
            host = "test4.com",
            ["mobile-version"] = "2.3.0"
          }
        })

        assert.response(r).has.status(500)
      end)
    end)
  end)
end
