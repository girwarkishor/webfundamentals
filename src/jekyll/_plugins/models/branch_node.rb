require File.expand_path('../node.rb', __FILE__)

class BranchNode < Node

  attr_reader :indexLeafNode

  def initialize(parentNode, id)
    super(parentNode)

    @branchId = id
    @indexLeafNode = nil
  end

  def addLeafChildNode(node)
    if node.primaryLanguagePage.data.has_key?('published') &&
      !(node.primaryLanguagePage.data['published'])
      # Not published so exclude from the tree
      return
    end

    if node.isIndexLeaf
      @indexLeafNode = node
    else
      @leafChildNodes << node
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

  def sortNodes()
    @leafChildNodes = @leafChildNodes.sort do |leafNodeA, leafNodeB|
      a_order = leafNodeA.primaryLanguagePage.data['order'] || leafNodeA.primaryLanguagePage.data['published_on'] || 0
      b_order = leafNodeB.primaryLanguagePage.data['order'] || leafNodeB.primaryLanguagePage.data['published_on'] || 0

      a_order <=> b_order
    end

    # This value is the default to make pages with no order to pushed to
    # the bottom allowing pages with an order to be at the top
    heavy_weight = 9999

    @branchChildNodes = @branchChildNodes.sort do |branchNodeA, branchNodeB|
      indexLeafA = branchNodeA.indexLeafNode
      indexLeafB = branchNodeB.indexLeafNode

      indexPageA = (indexLeafA.nil?) ? nil : indexLeafA.primaryLanguagePage
      indexPageB = (indexLeafB.nil?) ? nil : indexLeafB.primaryLanguagePage

      a_order = 0
      b_order = 0
      if !indexPageA.nil?
        a_order = indexPageA.data['order'] || indexPageA.data['published_on'] || heavy_weight
      end

      if !indexPageB.nil?
        b_order = indexPageB.data['order'] || indexPageB.data['published_on'] || heavy_weight
      end

      if a_order.is_a?(Integer) & b_order.is_a?(Integer)
          a_order <=> b_order
      elsif a_order.is_a?(Date) & b_order.is_a?(Date)
          a_order <=> b_order
      else
        0 <=> 0
      end
    end
  end

  def hasNodes()
    return @leafChildNodes.size > 0 || @branchChildNodes.size > 0 || (!@indexLeafNode.nil?)
  end

  def getNextLeafNode(leafNode)
    if leafNode == @indexLeafNode
      leafIndex = -1
    else
      leafIndex = @leafChildNodes.index(leafNode)
    end
    if leafIndex.nil?
      return nil
    end

    nextLeafIndex = leafIndex + 1
    if (nextLeafIndex < @leafChildNodes.size)
      return @leafChildNodes[nextLeafIndex]
    end

    return nil
  end

  def getPreviousLeafNode(leafNode)
    if leafNode == @indexLeafNode
      leafIndex = -1
    else
      leafIndex = @leafChildNodes.index(leafNode)
    end
    if leafIndex.nil?
      return nil
    end

    prevLeafIndex = leafIndex - 1
    if (prevLeafIndex >= 0 && prevLeafIndex < @leafChildNodes.size)
      return @leafChildNodes[prevLeafIndex]
    end

    if (prevLeafIndex == -1 && (!@indexLeafNode.nil?))
      return @indexLeafNode
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
