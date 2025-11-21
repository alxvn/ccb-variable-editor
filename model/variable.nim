type
    CopperCubeVariable* = ref object
        id*: int
        name*: string
        value*: string

type
  CopperCubeConfiguration* = ref object
    lastId*: int
    projectName*: string
    items*: seq[CopperCubeVariable]

