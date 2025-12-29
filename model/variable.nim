type
    CopperCubeVariable* = ref object
        id*: int
        name*: string
        value*: string
        desc*: string

type
  CopperCubeConfiguration* = ref object
    lastId*: int
    projectName*: string
    items*: seq[CopperCubeVariable]

