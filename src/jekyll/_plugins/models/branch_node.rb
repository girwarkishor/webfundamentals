require File.expand_path('../node.rb', __FILE__)
require File.expand_path('../../helpers/tree.rb', __FILE__)

class BranchNode < Node

  def initialize(parentNode, id)
    super(parentNode)

    @branchId = id
  end

  def addLeafChildNode(node)
    if node.primaryLanguagePage.data.has_key?('published') &&
      !(node.primaryLanguagePage.data['published'])
      # Not published so exclude from the tree
      return
    end

    @leafChildNodes << node
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
      if leafNodeA.isIndexLeaf
        a_order = -1
      else
        a_order = leafNodeA.primaryLanguagePage.data['order'] || leafNodeA.primaryLanguagePage.data['published_on'] || 0
      end

      if leafNodeB.isIndexLeaf
        b_order = -1
      else
        b_order = leafNodeB.primaryLanguagePage.data['order'] || leafNodeB.primaryLanguagePage.data['published_on'] || 0
      end

      if a_order.class == b_order.class
          a_order <=> b_order
      else
        0 <=> 0
      end
    end

    # This value is the default to make pages with no order to pushed to
    # the bottom allowing pages with an order to be at the top
    heavy_weight = 9999

    @branchChildNodes = @branchChildNodes.sort do |branchNodeA, branchNodeB|
      indexLeafA = TreeHelper.getIndexLeafNode(branchNodeA)
      indexLeafB = TreeHelper.getIndexLeafNode(branchNodeB)

      indexPageA = (indexLeafA.nil?) ? nil : indexLeafA.primaryLanguagePage
      indexPageB = (indexLeafB.nil?) ? nil : indexLeafB.primaryLanguagePage

      a_order = heavy_weight
      b_order = heavy_weight
      if !indexPageA.nil?
        a_order = indexPageA.data['order'] ||
          indexPageA.data['published_on'] ||
          branchNodeA.getId() ||
          indexPageA.data['title'] ||
          heavy_weight
      end

      if !indexPageB.nil?
        b_order = indexPageB.data['order'] ||
          indexPageB.data['published_on'] ||
          branchNodeB.getId() ||
          indexPageB.data['title'] ||
          heavy_weight
      end

      if a_order.class == b_order.class
          a_order <=> b_order
      else
        0 <=> 0
      end
    end
  end

  def shouldBeAddedToTree()
    if @leafChildNodes.size == 0 && @branchChildNodes.size == 0
      return false
    end

    indexLeaf = TreeHelper.getIndexLeafNode(self)
    if indexLeaf.nil?
      return false
    end

    if indexLeaf.primaryLanguagePage.data.has_key?('published') &&
      !(indexLeaf.primaryLanguagePage.data['published'])
      # Not published so exclude from the tree
      return false
    end

    return true
  end

  def getNextLeafNode(leafNode)
    leafIndex = @leafChildNodes.index(leafNode)
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
    leafIndex = @leafChildNodes.index(leafNode)
    if leafIndex.nil?
      return nil
    end

    prevLeafIndex = leafIndex - 1
    if (prevLeafIndex >= 0 && prevLeafIndex < @leafChildNodes.size)
      return @leafChildNodes[prevLeafIndex]
    end

    return nil
  end

  def getId()
    return @branchId
  end
end
