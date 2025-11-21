import os
import jsony
import json

import ../model/variable
import ../gens/ccb_extension

let appDir = splitFile(getAppFilename()).dir
let PROJECT_CONFIGS_FOLDER = appDir & "\\project_configs"

var items*: seq[CopperCubeVariable] = @[]
var lastId*: int

proc loadVariables*(variableConfigPath: string) =
    if fileExists(variableConfigPath):
        echo "Config file found."
        var configData = readFile(variableConfigPath).fromJson(CopperCubeConfiguration)
        lastId = configData.lastId
        items = configData.items
    else:
      items = @[]
      lastId = 0

proc getById*(id: int): CopperCubeVariable =
  for v in items:
    if v.id == id:
      return v
  return nil

proc getIndexById*(id: int): int =
  for i, v in items:
    if v.id == id:
      return i
  return -1

proc addVariableInfo*() =
    items.add(CopperCubeVariable(id: lastId, name: "", value: ""))
    lastId += 1

proc saveConfig*(projectName: string, configPath: string) =
    let curConf = CopperCubeConfiguration(
        projectName: projectName,
        lastId: lastId,
        items: items
    )
    if not dirExists(PROJECT_CONFIGS_FOLDER):
      createDir(PROJECT_CONFIGS_FOLDER)

    writeFile(configPath, curConf.toJson())

proc collectJs(): string =
    var jsCode = ""
    for item in items:
        jsCode = jsCode & "ccbSetCopperCubeVariable(" & item.name.escapeJson() & ", " & item.value.escapeJson() & ");\r\n"
    return jsCode

proc exportExtension*(projectName: string, configPath: string, extensionPostfix: string): string =
    saveConfig(projectName, configPath)
    var jsCode = collectJs()
    createExtension(jsCode, projectName, extensionPostfix)