# Package

version       = "0.1.0"
author        = "Bo Lopker"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["nhxn"]


# Dependencies

requires "nim >= 1.4.0"
requires "prologue == 0.4"
requires "karax == 1.1.3"
requires "lrucache == 1.1.3"


task api, "Only for api":
    exec "nim r src/api.nim"