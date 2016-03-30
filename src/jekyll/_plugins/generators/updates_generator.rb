# Copyright 2015 Google Inc. All rights reserved.
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

  require File.expand_path('../WFGenerator.rb', __FILE__)

  # Generate pagination for update pages

  class UpdatesTagPaginator < WFGenerator
    priority :low

    def generate(site)
      @contentSource = site.config['WFContentSource']
      @numberOfResultsPerPage = 10
      @tags = []
      @tagPageMapping = {}

      updateBranchNode = nil
      site.data['tipOfTree'].getBranchNodes().each { |branchNode|
        if (branchNode.getId() == 'updates')
          updateBranchNode = branchNode;
        end
      }

      # Skip out if update section is not there
      if updateBranchNode.nil?
        puts "Skipping updates - Can't find updates branch"
        return;
      end

      updatePostsBranchNode = nil
      updateBranchNode.getBranchNodes().each { |branch|
        if branch.getId() == 'posts'
          updatePostsBranchNode = branch
        end
      }

      # Skip out if update section is not there
      if updatePostsBranchNode.nil?
        puts "Skipping updates - Can't find updates/post branch"
        return;
      end

      #createTagsForUpdates(getPages(site, ['updates']))

      # Generate updates for subdirectories in the updates folder,
      # will skipp the tags folder automatically.

      desiredTagPromotions = {
        'news' => 'News',
        'devtools' => 'DevTools'
      }

      #desiredTagPromotions.each { |tagId, tagTitle|
      #  pages = @tagPageMapping[tagId]
      #  if pages.count == 0
      #    msg = 'The promoted tag (' + tag['tagId'] + ') doesn\'t have any pages!'
      #    throw new Error("Promoting Tag", msg);
      #  end
      #
      #  newSubsection = {'id' => tagId, "pages" => [], "subdirectories" => []}
      #  updateSection['subdirectories'] << newSubsection
      #}

      # Generate the updates for root
      # pages = getPages(site, ['updates'])
      # generatePaginationPages(site, nil, updateSection, pages, nil)
      updatePosts = []
      updatePostsBranchNode.getBranchNodes().each { |yearBranch|
        yearBranch.getBranchNodes().each { |monthBranch|
          monthBranch.getLeafNodes().each { |leafNode|
            primaryLangPage = leafNode.primaryLanguagePage
            if (!primaryLangPage.data.has_key?('published')) || primaryLangPage.data['published'] == true
              updatePosts << primaryLangPage
            end
          }
        }
      }

      generatePaginationPages(site, nil, updateBranchNode, updatePosts, nil)






      # Root level feeds for updates is generated in build-end-generator

      # generate tag pages
      #tagsSection = {'id' => 'tags', "pages" => [], "subdirectories" => []}
      #updateSection['subdirectories'] << tagsSection
      #generateTagPages(site, nil, tagsSection, pages)

      #updateSection['subdirectories'].each { |subdirectory|
      #  if ((subdirectory['id'] == 'tags') or  (subdirectory['id'] == 'posts'))
      #    next;
      #  end
      #
      #  pages = @tagPageMapping[subdirectory['id']]
      #  path = subdirectory['id']
      #  generatePaginationPages(site, path, subdirectory, pages, desiredTagPromotions[subdirectory['id']])
      #  generateSubdirectoryFeed(site, subdirectory)
      #}
    end

    def createTagsForUpdates(pages)
      # Iterate over every page and create an array of tags + pages that
      # have those tags.
      pages.each do |page|

        # If there are no tags, skip this page
        if page.data['tags'].nil?
          next
        end

        page.data['tags'].each do |tag|
          # Clean up the tag, strip whitespace and lower case it
          tag = tag.downcase.strip

          # Error on reserved words or if there is a space in the tag
          if tag === 'index' || tag === 'index.html'
            msg = 'Reserved tag name index[.html] (' + page.name + ')'
            raise ArgumentError.new("Create Tag Pages: " + msg);
          end
          if tag.index(' ') != nil
            msg = 'Spaces not permitted in tags! You have \'' + tag + '\' in the tag list of file: (' + page.name + ')'
            raise ArgumentError.new("Create Tag Pages: " + msg);
          end

          @tagPageMapping[tag] ||= []
          @tagPageMapping[tag] << page
          @tags << tag
        end
      end

      @tags.sort!
      @tags.uniq!
    end

    def generateSubdirectoryFeed(site, subdirectory)
      path = File.join('updates', subdirectory['id'])
      pages = getPages(site, ['updates', subdirectory['id']])

      site.pages << UpdatesFeedPage.new(site, path, site.data['curr_lang'], pages, WFFeedPage.FEED_TYPE_RSS)
      site.pages << UpdatesFeedPage.new(site, path, site.data['curr_lang'], pages, WFFeedPage.FEED_TYPE_ATOM)
    end

    def generatePaginationPages(site, path, updatesBranch, pages, title)
      # Filter out pages with dates only
      pages = pages.map { |page|
        puts page.data.keys
        if (requiredYamlFields - page.data.keys).empty? == false
          LogHelper.throwError("Update page found without a 'published_on' field. " + page.dir + page.name)
          next
        end

        page
      }

      pages = pages.sort { |x,y| y["published_on"] <=> x["published_on"] }
      numberOfPages = calculatePages(pages, @numberOfResultsPerPage)

      (0..(numberOfPages - 1)).each { |pageIndex|
        # Creat indices to include in the page results
        # -1 on endPageIndex accounts for zero indexing
        startPageIndex = pageIndex * @numberOfResultsPerPage
        endPageIndex = startPageIndex + @numberOfResultsPerPage - 1

        pagesToInclude = pages[startPageIndex..endPageIndex]

        leafNode = LeafNode.new(updatesBranch)

        updatePage = UpdatesPaginationPage.new(site, path, site.data['curr_lang'], pagesToInclude, pageIndex, numberOfPages, leafNode, title)

        leafNode.setPages(updatePage, [])
        updatesBranch.addLeafChildNode(leafNode)

        site.pages << updatePage
      }
    end

    def generateTagPages(site, path, tagsSection, pages)
      @tags.each do |tag|
        @tagPageMapping[tag].uniq!
        tagPage = UpdatesTagPage.new(site, path, site.data['curr_lang'], tag, @tagPageMapping[tag])
        tagPage.data['_context'] = tagsSection
        site.pages << tagPage
        tagsSection['pages'] << tagPage
      end

      tagPage = UpdatesTagsPage.new(site, path, site.data['curr_lang'], @tags)
      tagPage.data['_context'] = tagsSection
      site.pages << tagPage
      tagsSection['index'] = tagPage
    end

    def calculatePages(pages, numberOfResultsPerPage)
      (pages.size.to_f / numberOfResultsPerPage).ceil
    end

  end

end
