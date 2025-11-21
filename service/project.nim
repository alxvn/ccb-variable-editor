import os
import jsony
import wNim
import nuuid
import std/strformat
import std/sequtils
import std/random

import ../model/project

let appDir = splitFile(getAppFilename()).dir

# no idea why I can't use const here
# and I'm too lazy to figure out
let CONFIG_FILE = appDir & "\\config.json"
let PROJECT_CONFIGS_FOLDER = appDir & "\\project_configs"
const NOT_SELECTED_PROJECT_LABEL = "Not selected"

var projects*: seq[CopperCubeProject]

if fileExists(CONFIG_FILE):
    projects = readFile(CONFIG_FILE).fromJson(seq[CopperCubeProject])
else:
    projects = @[]
    
projects.insert(CopperCubeProject(friendlyName: NOT_SELECTED_PROJECT_LABEL, configPath: "", projectId: "", extensionPrefix: ""))
var selectedProject: CopperCubeProject = projects[0]

proc setCurrentProjectId*(index: int) =
    selectedProject = projects[index]
    echo fmt"Selected project {selectedProject.friendlyName}"

proc getCurrentProjectFriendlyName*(): string =
    return selectedProject.friendlyName

proc getCurrentProjectVariablesConfig*(): string =
    return selectedProject.configPath

proc getCurrentProjectExtensionPostfix*(): string =
    return selectedProject.extensionPrefix

proc isEmptyProjectSelected*(): bool =
    return selectedProject.projectId == ""

proc refreshProjectsList*(dropDown: wComboBox, selectLatests = false) = 
    dropDown.clear()

    for project in projects:
        dropDown.append(project.friendlyName)
    
    # select latest project if added a new one
    if selectLatests:
        dropdown.setSelection(projects.len - 1)
    else:
        dropDown.setSelection(0)
    
    for project in projects:
        echo fmt"Name: {project.friendlyName}, Path: {project.configPath}"

proc saveConfig() =
    writeFile(CONFIG_FILE, projects.filterIt(it.projectId != "").toJson())

randomize()

proc random6Letters(): string =
    const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    result = newString(6)
    for i in 0..5:
        result[i] = letters[rand(letters.len - 1)]
    return result

proc addNewProject*(newProjectName: string) = 
    let newguid = generateUUID()
    projects.add(CopperCubeProject(friendlyName: newProjectName, configPath: fmt"{PROJECT_CONFIGS_FOLDER}/{newguid}.json", projectId: newguid, extensionPrefix: random6Letters()))
    selectedProject = projects[projects.len - 1]
    saveConfig()

proc deleteSelectedProject*(index: int) =
    projects.delete(index)
    saveConfig()
