require File.expand_path('../node.rb', __FILE__)

class BranchNode < Node
  def initialize(parentNode, id)
    super(parentNode)

    @branchId = id
    @indexLeafNode = nil
  end

  def addLeafChildNode(node)
    @leafChildNodes << node
    if node.isIndexLeaf
      @indexLeafNode = node
    end
  end

  def addBranchChildNode(node)
    @branchChildNodes << node
  end

  def getLeafNodes()
    return @leafChildNodes
  end

  def getBranchNodes()
    return @branchChildNodes
  end

  def hasNodes()
    # TODO Check index page existance
    return @leafChildNodes.size > 0 || @branchChildNodes.size > 0
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

  def getId()
    return @branchId
  end

  def getIndexPage(langcode)
    if @indexLeafNode.nil?
      return nil
    end
    return @indexLeafNode.getPageForLang(langcode);
  end
end
