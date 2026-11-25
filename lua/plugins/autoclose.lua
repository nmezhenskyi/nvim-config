local pack = require("nikita.pack")

pack.on_event("InsertEnter", function()
   pack.load("autoclose.nvim")
   require("autoclose").setup()
end)
