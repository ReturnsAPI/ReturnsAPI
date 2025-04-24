# Element Types

class Text():
    """
    Standalone text element
    """

    def __init__(self):
        self.text = []



class Enum():
    """
    Enum element
    """

    def __init__(self):
        self.name = ""
        self.href = ""
        self.text = []



class Method():
    """
    Method element
    """

    def __init__(self):
        self.is_instance = False    # Affects prefix (`Class`. vs `wrapper:`)
        self.signatures = [ Signature() ]
        self.href = ""
        self.text = []



class Signature():
    """
    Signature of Method element
    """

    def __init__(self):
        self.name = ""
        self.ret = ""
        self.params = []
        self.optional = []