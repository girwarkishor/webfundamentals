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

  # in a StaticFile relative_path is a read only attribute
  # http://www.rubydoc.info/github/mojombo/jekyll/master/Jekyll/StaticFile#relative_path-instance_method

  class LanguageAsset < Jekyll::StaticFile
    def initialize(contentPath, relativeDir, filename)
      # We only support english assets in the current implementation
      @langcode = 'en'

      # IMPORTANT
      # @base, @dir and @name are used by Jekyll
      @base = contentPath
      @dir  = File.join(@langcode, relativeDir)
      @name = filename
    end


    def destination(dest)
      File.join(dest, @dir, @name)
    end
  end

end
