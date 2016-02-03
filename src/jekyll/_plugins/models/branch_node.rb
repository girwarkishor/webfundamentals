require File.expand_path('../node.rb', __FILE__)

class BranchNode < Node
  def initialize(parentNode)
    super(parentNode)
  end

  def addLeafChildNode(node)
    @leafChildNodes << node
  end

  def addBranchChildNode(node)
    @branchChildNodes << node
  end

  def getNextLeafNode(leafNode)
    nextLeafIndex = @leafChildNodes.index(leafNode) + 1
    if (nextLeafIndex < @leafChildNodes.size)
      return @leafChildNodes[nextLeafIndex]
    end
    return nil
  end

  def getPreviousLeafNode(leafNode)
    prevLeafIndex = @leafChildNodes.index(leafNode) - 1
    if (prevLeafIndex >= 0 && prevLeafIndex < @leafChildNodes.size)
      return @leafChildNodes[prevLeafIndex]
    end
    return nil
  end
end
