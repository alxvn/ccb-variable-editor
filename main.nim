import wNim
import std/strformat
import nimclipboard/libclipboard

import service/project as projectService
import service/variable as variableService
import gens/ccb_plugin as ccbPlugin

const APP_NAME = "CopperCube Variable Editor v0.1"

const WIN_X = 1024
const WIN_Y = 778
const HALF_WIN_X = (1024 / 2).int
const TOP_MENU_HEIGHT = 75
const MAIN_SECTION_INITIAL_POS = TOP_MENU_HEIGHT

const SMALL_BUTTON_SIZE = (75, 25).wSize
const SMALL_BUTTON_SIZE_2 = (85, 25).wSize

var cb = clipboard_new(nil)

var buttonsToDisableWithoutProjectSelected: seq[wButton] = @[]
var variableSections: seq[wStaticBox] = @[]

let app = App()
let frame = Frame(title=APP_NAME, size=(WIN_X, WIN_Y), style=wDefaultFrameStyle and not wResizeBorder)

frame.disableMaximizeButton()

let panel = frame.Panel()

let projectMenu = panel.StaticBox(size=(HALF_WIN_X - 20, TOP_MENU_HEIGHT - 1), label="Extension", pos=(15, 0))
let addProjectBtn = projectMenu.Button(pos=(5, 5), label="Add Extension", size = SMALL_BUTTON_SIZE_2)
let selectProjectDropDown = projectMenu.ComboBox(pos=(95, 6), size=(195,25))

let deleteProjectBtn = projectMenu.Button(pos=(300, 5), size = SMALL_BUTTON_SIZE, label="Del selected")
buttonsToDisableWithoutProjectSelected.add(deleteProjectBtn)

let generatePluginBtn = projectMenu.Button(pos=(385, 5), size = SMALL_BUTTON_SIZE_2, label="Config plugin")

proc setButtonsDisabled(isDisabled: bool) =
    for btn in buttonsToDisableWithoutProjectSelected:
        if isDisabled:
            btn.disable()
        else:
            btn.enable()

let variableMenu = panel.StaticBox(pos=(HALF_WIN_X, 0), size=(HALF_WIN_X - 30, TOP_MENU_HEIGHT - 1), label="Variables")

let addBtn = variableMenu.Button(pos=(5, 5), size=SMALL_BUTTON_SIZE, label="Add")
buttonsToDisableWithoutProjectSelected.add(addBtn)
let saveBtn = variableMenu.Button(pos=(85, 5), size=SMALL_BUTTON_SIZE, label="Save")
buttonsToDisableWithoutProjectSelected.add(saveBtn)
let exportBtn = variableMenu.Button(pos=(165, 5), size=(120,25), label="Export Extension")
buttonsToDisableWithoutProjectSelected.add(exportBtn)

# main section stuff
let mainSection = panel.StaticBox(size=(WIN_X - 45, 35), label="CopperCube Variables", pos=(15, TOP_MENU_HEIGHT))
let scroll = ScrollBar(parent=panel, style=wSbVertical, size=(15, WIN_Y - 100), pos=(WIN_X - 20, TOP_MENU_HEIGHT))
scroll.hide()

proc shiftMainSection() =
    let curScroll = scroll.getScrollPos()
    mainSection.position = (mainSection.position.x, MAIN_SECTION_INITIAL_POS - curScroll * 40)

proc updateScroll(shiftScroll=false, stayAtFirst=false) =
    if variableService.items.len <= 16:
        scroll.hide()
        shiftMainSection()
    else:
        let newRange = variableService.items.len - 16
        var nextScrollPos = if shiftScroll: newRange else: scroll.scrollPos
        # for initial start with many vars
        if stayAtFirst: nextScrollPos = 0
        scroll.show()
        scroll.setScrollbar(
            position = nextScrollPos,
            pageSize = 1,
            range = newRange
        )
        shiftMainSection()

proc clearAllSections() =
    # clear all sections and rebuild the ui to shift everything if required
    # use countdown for compilator not complain or something
    mainSection.size=(WIN_X - 45, 35)
    for i in countdown(variableSections.len - 1, 0):
        variableSections[i].destroy()
        variableSections.delete(i)
    variableSections = @[]

proc addSection(index: int, id: int, name="", value="") =
    let sectionBox = mainSection.StaticBox(pos=(0, 10 + 40 * index), size=(WIN_X - 65, 40), id=id)
    variableSections.add(sectionBox)
    
    sectionBox.StaticText(pos=(0,-6), size=(50,20), label="Name:")
    let variableNameInput = sectionBox.TextCtrl(pos=(50, -6), size=(220, 18), value=name)
    variableNameInput.wEvent_TextUpdate do():
        variableService.getById(variableNameInput.parent.id.int).name = variableNameInput.value
        for item in variableService.items:
            echo "{id: " & $item.id & ", name: \"" & item.name & "\", value: \"" & item.value & "\"}"

    let copyNameBtn = sectionBox.Button(pos=(280,-10), label="Copy", size=(75,25))
    copyNameBtn.wEvent_Button do():
        cb.clipboard_clear(LCB_CLIPBOARD)
        let name = variableNameInput.value
        discard cb.clipboard_set_text(name.cstring)

    sectionBox.StaticText(pos=(370,-6), size=(50,20), label="Value:")
    let variableValueInput = sectionBox.TextCtrl(pos=(420, -6), size=(400, 18), value=value)
    variableValueInput.wEvent_TextUpdate do():
        variableService.getById(variableValueInput.parent.id.int).value = variableValueInput.value
        for item in variableService.items:
            echo "{id: " & $item.id & ", name: \"" & item.name & "\", value: \"" & item.value & "\"}"
    
    let deleteRowBtn = sectionBox.Button(size=(75,25), label="Delete", pos=(WIN_X - 160, -10))
    deleteRowBtn.wEvent_Button do():
        # TODO logic should be moved inside service
        # this one is from POC
        var indexToRemove = variableService.getIndexById(variableNameInput.parent.id.int)
        variableService.items.delete(indexToRemove)

        clearAllSections()

        for i, v in variableService.items:
            addSection(i, v.id, v.name, v.value)

        panel.refresh()
    
    mainSection.size = (mainSection.size.width, mainSection.size.height + 40)
    updateScroll(true)

addBtn.wEvent_Button do():
    addSection(variableService.items.len, variableService.lastId)
    variableService.addVariableInfo()

saveBtn.wEvent_Button do():
    variableService.saveConfig(projectService.getCurrentProjectFriendlyName(), projectService.getCurrentProjectVariablesConfig())

exportBtn.wEvent_Button do():
    var extOutputPath = variableService.exportExtension(projectService.getCurrentProjectFriendlyName(),
        projectService.getCurrentProjectVariablesConfig(),
        projectService.getCurrentProjectExtensionPostfix())
    let msg = "Extension is exported to " & extOutputPath
    var exportMsgDlg: wMessageDialog = MessageDialog(caption="Export message", message=msg, style=wOk)
    discard exportMsgDlg.display()

addProjectBtn.wEvent_Button do():
    let addProjectDialog = TextEntryDialog(message = "Input New Extension name", caption="Add Extension dialog")

    addProjectDialog.wEvent_DialogClosed do():
        let userInput = addProjectDialog.getValue()
        if userInput != "":
            projectService.addNewProject(userInput)
            selectProjectDropDown.refreshProjectsList(true)
            setButtonsDisabled(false)

            clearAllSections()
            loadVariables(projectService.getCurrentProjectVariablesConfig())

            for i, v in variableService.items:
                addSection(i, v.id, v.name, v.value)
            panel.refresh()
            updateScroll(true)
            
    addProjectDialog.display()

deleteProjectBtn.wEvent_Button do():
    let confirmDeletionDialog = MessageDialog(
        style = wYesNo,
        message = fmt"Are you sure you want to remove {projectService.getCurrentProjectFriendlyName()}?",
        caption = "Delete Extension")
    
    let isConfirmed = confirmDeletionDialog.display() == wIdYes
    if isConfirmed:
        projectService.deleteSelectedProject(selectProjectDropDown.getSelection())
        selectProjectDropDown.refreshProjectsList()
        setButtonsDisabled(true)

generatePluginBtn.wEvent_Button do():
    ccbPlugin.createPlugin()

selectProjectDropDown.wEvent_ComboBox do():
    projectService.setCurrentProjectId(selectProjectDropDown.getSelection())
    setButtonsDisabled(projectService.isEmptyProjectSelected())
    # project vars
    clearAllSections()
    loadVariables(projectService.getCurrentProjectVariablesConfig())

    for i, v in variableService.items:
        addSection(i, v.id, v.name, v.value)
    panel.refresh()

    updateScroll(true)

scroll.wEvent_ScrollThumbTrack do ():
    shiftMainSection()

# last part disable stuff
# run etc
selectProjectDropDown.refreshProjectsList()
if projectService.isEmptyProjectSelected():
    setButtonsDisabled(true)

frame.center()
frame.show()
app.mainLoop()
