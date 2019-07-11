local typedefs = require "kong.db.schema.typedefs"


return {
  name = "myplugin",
  fields = {
    {
      consumer = typedefs.no_consumer
    },
    {
      config = {
        type = "record",
        fields = {
          {
            blacklist = {
              type = "array",
              elements = {
                type = "record",
                fields = {
                  {
                    method = {
                      type = "string",
                      default = "GET"
                    }
                  },
                  {
                    host = {
                      type = "string"
                    }
                  },
                  {
                    path = {
                      type = "string"
                    }
                  },
                  {
                    version_range = {
                      type = "array",
                      elements = {
                        type = "string"
                      },
                      default = {}
                    }
                  }
                }
              },
              default = {}
            }
          }
        }
      }
    }
  }
}
