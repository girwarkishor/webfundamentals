# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Jekyll
  class TreeHelper
    def self.getSiblingPages(branchNode, langcode)
      siblingPages = []
      siblingLeafs = branchNode.getLeafNodes()
      siblingLeafs.each { |siblingLeaf|
        page = siblingLeaf.getPageForLang(langcode)
        if page.nil?
          next
        end
        siblingPages << page
      }
      return siblingPages
    end

    def self.getSubdirectories(branchNode, langcode)
      subdirectories = []
      branchNodes = branchNode.getBranchNodes()
      branchNodes.each { |branch|
        if branch.nil?
          next
        end

        if !branch.hasNodes()
          next
        end

        subdirectories << {
          "id" => branch.getId(),
          "index" => branch.getIndexPage(langcode),
          "pages" => TreeHelper.getSiblingPages(branch, langcode),
          "subdirectories" => []
        }
      }
      return subdirectories
    end

    def self.getNextPage(leafNode, langcode)
      branchNode = leafNode.getParent()
      nextLeaf = branchNode.getNextLeafNode(leafNode)
      if (nextLeaf.nil?)
        return nil
      else
        return nextLeaf.getPageForLang(langcode)
      end
    end

    def self.getPrevPage(leafNode, langcode)
      branchNode = leafNode.getParent()
      prevLeaf = branchNode.getPreviousLeafNode(leafNode)
      if (prevLeaf.nil?)
        return nil
      else
        return prevLeaf.getPageForLang(langcode)
      end
    end

    def self.getBranchId(branchNode)
      return branchNode.getId()
    end
  end
end
