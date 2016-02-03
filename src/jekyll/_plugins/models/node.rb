class Node
  def initialize(parentNode)
    @parentNode = parentNode
    @leafChildNodes = []
    @branchChildNodes = []
  end

  def getParent()
    return @parentNode
  end
end
